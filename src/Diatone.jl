module Diatone

using XCB
#TODO: add `handle_events` to WindowAbstractions once we figure out a good way to deal with concurrency
using XCB: handle_events
using Lava: Lava, unwrap, Surface, Swapchain, Vk, set_presentation_queue, RenderGraph, Instance, Device, CompactRecord, FrameCycle, cycle!, RenderGraph, ExecutionState, request_command_buffer, SubmissionInfo, ensure_layout
using WindowAbstractions
using AbstractGUI: WindowManager
using Dictionaries

import XCB: XCBWindow
import Base: close, run
import Lava: render

const Optional{T} = Union{T, Nothing}
const Window = XCBWindow

include("concurrency.jl")
include("render.jl")
include("application.jl")

export Application, Window, render, shutdown

end
