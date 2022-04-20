struct RunningState
  event_loop::SpawnedTask
  rendering_loop::SpawnedTask
end

function Base.wait(running::RunningState)
  wait(running.event_loop)
  wait(running.rendering_loop)
end

function cancel(state::RunningState)
  cancel(state.event_loop)
  cancel(state.rendering_loop)
end

mutable struct Application
  const renderer::Renderer
  const wm::XWindowManager
  const ui::UIOverlay{XCBWindow}
  running::Optional{RunningState}
end

function Application(; release = false)
  instance, device = Lava.init(; debug = !release, with_validation = !release, instance_extensions = ["VK_KHR_xcb_surface"])

  Application(Renderer(instance, device), XWindowManager(), UIOverlay{XCBWindow}(), nothing)
end

active_windows(app::Application) = keys(app.renderer.render)

function Base.show(io::IO, ::MIME"text/plain", app::Application)
  print(io, "Application(", length(active_windows(app)), " windows)")
end

function XCBWindow(app::Application, title::AbstractString; screen = current_screen(app.wm), x = 0, y = 0, width = 1800, height = 950, map = false, attributes = [XCB.XCB_CW_BACK_PIXEL], values = [screen.black_pixel], kwargs...)
  win = XCBWindow(app.wm, title; screen, x, y, width, height, map, attributes, values, kwargs...)
  overlay(app.ui, win, [])
  set_callbacks!(app, win, WindowCallbacks())
  add_frame_cycle(app.renderer, win)
  win
end

function WindowAbstractions.WindowCallbacks(app::Application, callbacks::WindowCallbacks)
  callbacks.on_close === WindowAbstractions.default_on_close || error("The callback for `on_close` is reserved.")
  WindowCallbacks(;
      on_close = (wm, ed) -> close(app, ed),
      callbacks.on_invalid,
      callbacks.on_resize,
      callbacks.on_expose,

      # React to all events.
      on_mouse_button_pressed  = ed -> (execute_callback(callbacks, ed); react_to_event(app.ui, ed)),
      on_mouse_button_released = ed -> (execute_callback(callbacks, ed); react_to_event(app.ui, ed)),
      on_pointer_move          = ed -> (execute_callback(callbacks, ed); react_to_event(app.ui, ed)),
      on_pointer_enter         = ed -> (execute_callback(callbacks, ed); react_to_event(app.ui, ed)),
      on_pointer_leave         = ed -> (execute_callback(callbacks, ed); react_to_event(app.ui, ed)),
      on_key_pressed           = ed -> (execute_callback(callbacks, ed); react_to_event(app.ui, ed)),
      on_key_released          = ed -> (execute_callback(callbacks, ed); react_to_event(app.ui, ed)),
  )
end

function set_callbacks!(app::Application, win::XCBWindow, callbacks::WindowCallbacks)
  set_callbacks!(app.wm, win, WindowCallbacks(app, callbacks))
end

close(app::Application, win::XCBWindow) = close(app, CloseWindow(win))
function close(app::Application, exc::CloseWindow)
  (; win) = exc
  delete!(app.ui.areas, win)
  delete_frame_cycle(app.renderer, win)
  WindowAbstractions.default_on_close(app.wm, exc)
end

render(app::Application) = render(app.renderer)
function render(f, app::Application, win::XCBWindow)
  set!(app.renderer.render, win, f)
end


"""
Run the application's event and rendering loops.

The event loop handles window events via WindowAbstractions.
The rendering loop handles graphics rendering via Lava.
"""
function run(app::Application; wait = true)
  !isnothing(app.running) && cancel(app.running)
  foreach(map_window, keys(app.renderer.render))
  t0 = time()
  event_loop = @spawn !isempty(active_windows(app)) handle_events(app.wm, t0)
  rendering_loop = @spawn render(app)
  app.running = RunningState(event_loop, rendering_loop)
  wait && Diatone.wait(app.running)
  nothing
end

function shutdown(app::Application)
  !isnothing(app.running) && cancel(app.running)
  for win in active_windows(app)
    close(app, win)
  end
  app.running = nothing
end
