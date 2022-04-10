module Diatone

using WindowAbstractions
using XCB
using AbstractGUI
using Lava

const Optional{T} = Union{T, Nothing}

include("target.jl")
include("render.jl")
include("BaseWidgets.jl")
include("application.jl")
include("main.jl")

end
