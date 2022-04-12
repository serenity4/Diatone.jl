mutable struct Renderer
  const instance::Instance
  const device::Device
  rg::Optional{RenderGraph}
  frame_dependencies::Vector{Any}
  const targets::Dictionary{XCBWindow,Target}
  const materials::Dictionary{UInt64,Any}
end

function render(rec::CompactRecord, rdr::Renderer, window::XCBWindow, app)
  ds = draw_state(rec, app)
  for object in rdr.pending_objects[window]
    prog = program(object, rdr.rg.device)
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

"""
    program(object, device::Device)

Get a program for an object to render.
"""
function program end

function render(app::Application)
  for window in active_windows(app.wm)
    #TODO: Only render new/invalidated widgets to improve performance.
    objects = app.widgets[window]
    initialize_target(app.renderer, window, objects)
    render_target(rdr, app, window)
  end
end

get_material!(f, rdr, object) = get_material!(f, rdr, material_hash(object))
get_material!(f, rdr, hash::UInt64) = get(f, rdr.materials, hash)
