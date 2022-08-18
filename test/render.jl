function render_on_color_attachment(graphics, rg, objects, color_attachment)
  for obj in objects
    rec = StatefulRecording()
    set_program(rec, program(obj, rg.device))
    set_invocation_state(rec, setproperties(invocation_state(rec), (;
      primitive_topology = Vk.PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP,
      triangle_orientation = Vk.FRONT_FACE_COUNTER_CLOCKWISE,
    )))
    set_data(rec, rg, invocation_data(obj))
    draw(graphics, rec, indices(obj), color_attachment)
  end
end
