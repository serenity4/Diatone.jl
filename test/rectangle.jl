struct PosColor
  pos::Vec{2,Float32}
  color::Arr{3,Float32}
end

function rectangle_vert(frag_color, position, index, data_address::DeviceAddressBlock)
  data = Pointer{Vector{PosColor}}(data_address)[index]
  (; pos, color) = data
  position[] = Vec(pos.x, pos.y, 0F, 1F)
  frag_color[] = Vec(color[0U], color[1U], color[2U], 1F)
end

function rectangle_frag(out_color, frag_color)
  out_color[] = frag_color
end

struct Rectangle
  vertices::Vector{PosColor}
end
indices(rect::Rectangle) = 1:4
invocation_data(rect::Rectangle) = rect.vertices

function program(::Rectangle, device)
  vert = @vertex device.spirv_features rectangle_vert(::Output::Vec{4,Float32}, ::Output{Position}::Vec{4,Float32}, ::Input{VertexIndex}::UInt32, ::PushConstant::DeviceAddressBlock)
  frag = @fragment device.spirv_features rectangle_frag(::Output::Vec{4,Float32}, ::Input::Vec{4,Float32})
  Program(device, vert, frag)
end
