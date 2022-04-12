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

function rectangle_vert(position, index, dd)
  pos = Pointer{Vector{Vec{2,Float32}}}(dd.vertex_data)[index]
  position[] = Vec(pos.x, pos.y, 0F, 1F)
end

function rectangle_frag(out_color, dd)
  out_color[] = Pointer{Vec{4,Float32}}(dd.material_data)[]
end

function Diatone.program(::Rectangle, device::Device)
  vert = @vertex device.spirv_features rectangle_vert(::Output{Position}::Vec{4,Float32}, ::Input{VertexIndex}::UInt32, ::PushConstant::DrawData)
  frag = @fragment device.spirv_features rectangle_frag(::Output::Vec{4,Float32}, ::PushConstant::DrawData)

  Program(device, vert, frag)
end

function Diatone.render(rec, window, rect::Rectangle)
  set_material(rec, rect.color)
  set = PointSet(Translated(rect.area, Translation(rect.location)), Point{2,Float32})
  idata = [1, 2, 3, 3, 2, 4]
  Diatone.draw_on_window(rec, window, set.points, idata, alignment = 4)
end
