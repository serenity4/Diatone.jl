module Diatone

using XCB
using Lava: Lava, unwrap, Surface, Swapchain, Vk, set_presentation_queue, RenderGraph, Instance, Device, CompactRecord, FrameCycle, cycle!, RenderGraph
using WindowAbstractions
using AbstractGUI: WindowManager
using Dictionaries

import XCB: XCBWindow
import Base: close, run
import Lava: render

const Optional{T} = Union{T, Nothing}
const Window = XCBWindow

include("render.jl")
include("application.jl")
include("main.jl")

export Application, Window, render

end
