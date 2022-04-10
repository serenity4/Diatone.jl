module BaseWidgets

using Dictionaries
using GeometryExperiments
using Lava
using SPIRV

import ..Diatone

struct Rectangle
  location::Point{2,Float32}
  area::Box{2,Float32}
  color::NTuple{4,Float32}
end

function rectangle_vert(frag_color, position, index, dd)
  vd = Pointer{Vector{VertexDataRectangle}}(dd.vertex_data)[index]
  (; pos, color) = vd
  position[] = Vec(pos.x, pos.y, 0F, 1F)
  frag_color[] = Vec(color[0U], color[1U], color[2U], 1F)
end

function rectangle_frag(out_color, frag_color)
  out_color[] = frag_color
end

function Diatone.program(rect::Rectangle, device)
  vert_interface = ShaderInterface(
    storage_classes = [SPIRV.StorageClassOutput, SPIRV.StorageClassOutput, SPIRV.StorageClassInput, SPIRV.StorageClassPushConstant],
    variable_decorations = dictionary([
      1 => dictionary([SPIRV.DecorationLocation => [0U]]),
      2 => dictionary([SPIRV.DecorationBuiltIn => [SPIRV.BuiltInPosition]]),
      3 => dictionary([SPIRV.DecorationBuiltIn => [SPIRV.BuiltInVertexIndex]]),
    ]),
    features = device.spirv_features,
  )

  frag_interface = ShaderInterface(
    execution_model = SPIRV.ExecutionModelFragment,
    storage_classes = [SPIRV.StorageClassOutput, SPIRV.StorageClassInput],
    variable_decorations = dictionary([
      1 => dictionary([SPIRV.DecorationLocation => [0U]]),
      2 => dictionary([SPIRV.DecorationLocation => [0U]]),
    ]),
    features = device.spirv_features,
  )

  vert_shader = @shader vert_interface rectangle_vert(::Vec{4,Float32}, ::Vec{4,Float32}, ::UInt32, ::DrawData)
  frag_shader = @shader frag_interface rectangle_frag(::Vec{4,Float32}, ::Vec{4,Float32})
  Program(device, vert_shader, frag_shader)
end

function Diatone.render(rec, window, rect::Rectangle, rdr)
  set = PointSet(Translated(rect.box, Translation(rect.location)), Point{2,Float32})
  vdata = map(point -> (point, rect.color), set.points)
  idata = [1, 2, 3, 3, 2, 4]
  Diatone.draw_on_window(rec, window, vdata, idata, alignment = 4)
end

end
