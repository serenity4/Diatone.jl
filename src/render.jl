mutable struct Renderer
  instance::Instance  #=const=#
  device::Device  #=const=#
  fg::Optional{FrameGraph}
  targets::Dictionary{XCBWindow,Target}  #=const=#
  materials::Dictionary{UInt64,Any}  #=const=#
end

function Renderer(wm::WindowManager)
  instance, device = init(
    instance_extensions = ["VK_KHR_surface", "VK_KHR_xcb_surface"],
    device_extensions = ["VK_KHR_swapchain"],
    device_specific_features = [:shader_int_64, :sampler_anisotropy],
  )
  # Don't build the frame graph until we have a target to render to.
  Renderer(instance, device, nothing, [])
end

function initialize_target(fg::FrameGraph, target::Target)
  color = color_attachment(fg.device, target.window, target.surface)
  name = attachment_name(target.window)
  register(fg.frame, name, color)
  add_resource(fg, name, AttachmentResourceInfo(Lava.format(color)))
end

function initialize_target(rdr::Renderer, window::XCBWindow, objects)
  target = get!(rdr.targets, window) do
    TargetInfo(window, rdr.fg.device, objects)
  end
  initialize_target(rdr.fg, window, target)
end

function color_attachment(target::Target)
  view =
  # We'll assume we won't read from the color attachment.
    color_attachment = Attachment(View(color_image), WRITE)
end

attachment_name(window::XCBWindow) = Symbol(:color_, window.id)

const RENDERER_MAIN_RENDER_PASS_NAME = :main

function render_target(rdr::Renderer, app, window::XCBWindow)
  #TODO: Make sure the window extent matches the attachment size.
  add_pass!(rdr.fg, RENDERER_MAIN_RENDER_PASS_NAME, RenderPass((0, 0, extent(window)...))) do rec
    render(rec, rdr, window, app)
  end
  add_resource_usage!(rdr.fg, resource_usage(rdr))
  #TODO: Do NOT clear if widgets are rendered conditionally.
  clear_attachments(rdr.fg, RENDERER_MAIN_RENDER_PASS_NAME, [attachment_name(window)])
end

function draw_on_window(rec, window, vdata, idata; kwargs...)
  draw(rec, TargetAttachments([attachment_name(window)]), vdata, idata; kwargs...)
end

function render(rec::CompactRecord, rdr::Renderer, window::XCBWindow, app)
  ds = draw_state(rec, app)
  for object in rdr.pending_objects[window]
    prog = program(object, rdr.fg.device)
    !isnothing(prog) && set_program(rec, prog)
    # Reset draw state to application default.
    set_draw_state(rec, ds)
    render(rec, window, object, rdr)
  end
end

draw_state(rec, app) = draw_state(rec)

"""
    render(rec::CompactRecord, object, rdr::Renderer)

Render an object.

Should typically set render state (if required) and perform draw calls.
"""
function render end

program(object, device) = nothing

function render(app)
  for window in active_windows(app.wm)
    #TODO: Only render new/invalidated widgets to improve performance.
    objects = app.widgets[window]
    initialize_target(app.renderer, window, objects)
    render_target(rdr, app, window)
  end
end

get_material!(f, rdr, object) = get_material!(f, rdr, material_hash(object))
get_material!(f, rdr, hash::UInt64) = get(f, rdr.materials, h)
