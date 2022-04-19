draw_state(obj) = Lava.DrawState()

function render_on_color_attachment(rec, device, objects, color_attachment)
  for obj in objects
    set_material(rec, material(obj))
    set_draw_state(rec, draw_state(obj))
    set_program(rec, program(obj, device))
    draw(rec, vertices(obj), indices(obj), color_attachment; alignment = alignment(obj))
  end
end
