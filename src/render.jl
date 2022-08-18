struct PendingRendering
  rg::RenderGraph
  exec::ExecutionState
end

mutable struct Renderer
  instance::Instance
  device::Device
  frame_cycle::Dictionary{XCBWindow, FrameCycle{XCBWindow}}
  render::Dictionary{XCBWindow, Any}
  pending::Dictionary{XCBWindow, PendingRendering}
  task::Task
  function Renderer(instance, device)
    rdr = new(instance, device, Dictionary(), Dictionary(), Dictionary())
    rdr.task = @spawn LoopExecution(0.005) render(rdr)
    finalizer(delete_frame_cycles, rdr)
  end
end

function Renderer(; release = false)
  instance, device = Lava.init(; debug = !release, with_validation = !release, instance_extensions = ["VK_KHR_xcb_surface"])
  Renderer(instance, device)
end

function add_frame_cycle(rdr::Renderer, win::XCBWindow)
  (; device) = rdr
  surface = xcb_surface(rdr.instance, win)
  isnothing(device.queues.present_queue) && set_presentation_queue(device, [surface])
  swapchain = Swapchain(device, surface, Vk.IMAGE_USAGE_COLOR_ATTACHMENT_BIT)
  cycle = FrameCycle(device, swapchain)
  insert!(rdr.frame_cycle, win, cycle)
  cycle
end

function xcb_surface(instance, win::XCBWindow)
  handle = unwrap(Vk.create_xcb_surface_khr(instance, Vk.XcbSurfaceCreateInfoKHR(win.conn.h, win.id)))
  Surface(handle, win)
end

function delete_frame_cycle(rdr::Renderer, win::XCBWindow)
  if haskey(rdr.pending, win)
    wait(rdr.pending[win].exec)
    delete!(rdr.pending, win)
  end
  haskey(rdr.frame_cycle, win) && delete!(rdr.frame_cycle, win)
  haskey(rdr.render, win) && delete!(rdr.render, win)
end

function delete_frame_cycles(rdr::Renderer)
  for win in keys(rdr.frame_cycle)
    delete_frame_cycle(rdr, win)
  end
end

set_render!(f, rdr::Renderer, win::XCBWindow) = set!(rdr.render, win, f)

function render(rdr::Renderer)
  for (win, fc) in pairs(rdr.frame_cycle)
    f = get(rdr.render, win, nothing)
    isnothing(f) && continue
    idx = acquire_next_image(fc)
    idx isa Int && render(rdr.render[win], rdr, win, idx)
  end
end

function render(f, rdr::Renderer, win::XCBWindow, idx::Integer)
  rg_ref = Ref{RenderGraph}()
  info = cycle!(rdr.frame_cycle[win], idx) do image
    rg = RenderGraph(rdr.device)
    rg_ref[] = rg
    f(rg, image)
    cb = request_command_buffer(rdr.device)
    baked = render!(rg, cb)
    ensure_layout(cb, image, Vk.IMAGE_LAYOUT_PRESENT_SRC_KHR)
    info = SubmissionInfo(cb)
    push!(info.release_after_completion, baked)
    info
  end
  # Wait for previous rendering.
  haskey(rdr.pending, win) && wait(rdr.pending[win].exec)
  set!(rdr.pending, win, PendingRendering(rg_ref[], info))
end
