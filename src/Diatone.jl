module Diatone

using XCB
using Lava: unwrap, Surface, Swapchain, Vk, set_presentation_queue
using WindowAbstractions
using AbstractGUI: WindowManager
using Dictionaries

const Optional{T} = Union{T, Nothing}

include("render.jl")
include("application.jl")
include("main.jl")

end
