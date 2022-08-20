module Diatone

using Reexport
using XCB
using Lava: Lava, Surface, Swapchain, Vk, set_presentation_queue, RenderGraph, Instance, Device, CompactRecord, FrameCycle, cycle!, RenderGraph, ExecutionState, request_command_buffer, SubmissionInfo, ensure_layout, acquire_next_image
@reexport using Lava
using AbstractGUI: react_to_event
using Dictionaries
using Base: RefValue
@reexport using ConcurrencyGraph
@reexport using WindowAbstractions
@reexport using AbstractGUI: UIOverlay, InputArea, InputAreaCallbacks

import Base: close
@reexport import XCB: set_callbacks!
@reexport import AbstractGUI: overlay
import Lava: render!, render

export render

const Optional{T} = Union{T, Nothing}
const Window = XCBWindow

include("render.jl")
include("ui.jl")
include("application.jl")

export Application, UserInterface, Renderer, create_window, Window, set_callbacks

end
