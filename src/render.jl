struct PendingRendering
  rg::RenderGraph
  exec::ExecutionState
end

struct Renderer
  instance::Instance
  device::Device
  frame_cycle::Dictionary{XCBWindow, FrameCycle{XCBWindow}}
  render::Dictionary{XCBWindow, Any}
  pending::Dictionary{XCBWindow, PendingRendering}
end

Renderer(instance, device) = Renderer(instance, device, Dictionary(), Dictionary(), Dictionary())

function add_frame_cycle(rdr::Renderer, win::XCBWindow)
  (; device) = rdr
  surface = xcb_surface(rdr.instance, win)
  isnothing(device.queues.present_queue) && set_presentation_queue(device, [surface])
  swapchain = Swapchain(device, surface, Vk.IMAGE_USAGE_COLOR_ATTACHMENT_BIT)
  cycle = FrameCycle(device, swapchain)
  insert!(rdr.frame_cycle, win, cycle)
end

function xcb_surface(instance, win::XCBWindow)
  handle = unwrap(Vk.create_xcb_surface_khr(instance, Vk.XcbSurfaceCreateInfoKHR(win.conn.h, win.id)))
  Surface(handle, win)
end

function delete_frame_cycle(rdr::Renderer, win::XCBWindow)
  (; swapchain) = rdr.frame_cycle[win]
  if haskey(rdr.pending, win)
    wait(rdr.pending[win].exec)
    delete!(rdr.pending, win)
  end
  delete!(rdr.frame_cycle, win)
  delete!(rdr.render, win)

  finalize(swapchain.handle)
  finalize(swapchain.surface.handle)
end

"""
    render(rec::CompactRecord, object, rdr::Renderer)

Render an object.

Should typically set render state (if required) and perform draw calls.
"""
function render end

"""
    program(object, device::Device)

Get a program for an object to render.
"""
function program end

function render(f, rdr::Renderer, win::XCBWindow)
  rg_ref = Ref{RenderGraph}()
  info = cycle!(rdr.frame_cycle[win]) do image
    rg = RenderGraph(rdr.device)
    rg_ref[] = rg
    f(rg, image)
    cb = request_command_buffer(rdr.device)
    baked = render(cb, rg)
    ensure_layout(cb, image, Vk.IMAGE_LAYOUT_PRESENT_SRC_KHR)
    info = SubmissionInfo(cb)
    push!(info.release_after_completion, baked)
    info
  end
  set!(rdr.pending, win, PendingRendering(rg_ref[], info))
end

function Base.wait(rdr::Renderer)
  wait([exec for (; exec) in rdr.pending])
end

function render(rdr::Renderer)
  for (win, f) in pairs(rdr.render)
    render(f, rdr, win)
  end
end
