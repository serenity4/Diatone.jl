struct Renderer
  instance::Instance
  device::Device
  rg::RenderGraph
  frame_cycle::Dictionary{XCBWindow, FrameCycle{XCBWindow}}
  materials::Dictionary{UInt64,Any}
end

Renderer(instance, device) = Renderer(instance, device, RenderGraph(device), Dictionary(), Dictionary())

function add_frame_cycle(rdr::Renderer, win::XCBWindow)
  (; device) = rdr
  surface = xcb_surface(rdr.instance, win)
  isnothing(device.queues.present_queue) && set_presentation_queue(device, [surface])
  swapchain = Swapchain(device, surface, Vk.IMAGE_USAGE_COLOR_ATTACHMENT_BIT)
  cycle = FrameCycle(device, swapchain)
  insert!(rdr.frame_cycles, win, cycle)
end

function xcb_surface(instance, win::XCBWindow)
  handle = unwrap(Vk.create_xcb_surface_khr(instance, Vk.XcbSurfaceCreateInfoKHR(win.conn.h, win.id)))
  Surface(handle, win)
end

function delete_frame_cycle(rdr::Renderer, win::XCBWindow)
  (; swapchain) = rdr.frame_cycles[win]
  delete!(rdr.frame_cycles, win)

  # Can wait for rendering to finish first if it causes issues.
  finalize(swapchain.handle)
  finalize(swapchain.surface.handle)
end

function render(rec::CompactRecord, rdr::Renderer, window::XCBWindow)
  ds = draw_state(rec)
  for object in rdr.pending_objects[window]
    prog = program(object, rdr.rg.device)
    !isnothing(prog) && set_program(rec, prog)
    # Reset draw state to application default.
    set_draw_state(rec, ds)
    render(rec, window, object, rdr)
  end
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

get_material!(f, rdr, object) = get_material!(f, rdr, material_hash(object))
get_material!(f, rdr, hash::UInt64) = get(f, rdr.materials, hash)
