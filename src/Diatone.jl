module Diatone

using XCB
#TODO: add `handle_events` to WindowAbstractions once we figure out a good way to deal with concurrency
using XCB: handle_events
using Lava: Lava, unwrap, Surface, Swapchain, Vk, set_presentation_queue, RenderGraph, Instance, Device, CompactRecord, FrameCycle, cycle!, RenderGraph, ExecutionState, request_command_buffer, SubmissionInfo, ensure_layout
using WindowAbstractions
using AbstractGUI: UIOverlay, react_to_event, InputArea, InputAreaCallbacks, overlay
using Dictionaries

using Base: RefValue

import XCB: XCBWindow, set_callbacks!
import Base: close, run, wait
import Lava: render

const Optional{T} = Union{T, Nothing}
const Window = XCBWindow

include("concurrency.jl")
include("render.jl")
include("ui.jl")
include("application.jl")

export Application, Window, render, shutdown, cancel

end
