module Diatone

using Reexport
using XCB
using Lava: Lava, Surface, Swapchain, Vk, set_presentation_queue, RenderGraph, Instance, Device, CompactRecord, FrameCycle, cycle!, RenderGraph, ExecutionState, request_command_buffer, SubmissionInfo, ensure_layout, acquire_next_image
using AbstractGUI: UIOverlay, react_to_event, InputArea, InputAreaCallbacks, overlay
using Dictionaries
@reexport using ConcurrencyGraph
@reexport using WindowAbstractions

using Base: RefValue

@reexport import XCB: set_callbacks!
import Base: close
@reexport import Lava: render

const Optional{T} = Union{T, Nothing}
const Window = XCBWindow

include("render.jl")
include("ui.jl")
include("protection.jl")
include("application.jl")

export Application, UserInterface, Renderer, create_window, Window

end
