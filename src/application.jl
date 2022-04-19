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
  const wm::WindowManager{XWindowManager,XCBWindow}
  running::Optional{RunningState}
end

function Application(; release = false)
  instance, device = Lava.init(; debug = !release, with_validation = !release, instance_extensions = ["VK_KHR_xcb_surface"])

  Application(Renderer(instance, device), WindowManager(XWindowManager()), nothing)
end

active_windows(app::Application) = keys(app.renderer.render)

function Base.show(io::IO, ::MIME"text/plain", app::Application)
  print(io, "Application(", length(active_windows(app)), " windows)")
end

function XCBWindow(app::Application, title::AbstractString; screen = current_screen(app.wm.impl), x = 0, y = 0, width = 1800, height = 950, map = false, attributes = [XCB.XCB_CW_BACK_PIXEL], values = [screen.black_pixel], kwargs...)
  win = XCBWindow(app.wm, title; screen, x, y, width, height, map, attributes, values, kwargs...)
  set_callbacks!(app.wm, win, WindowCallbacks(on_close = Base.Fix1(close, app)))
  add_frame_cycle(app.renderer, win)
  win
end

close(app::Application, win::XCBWindow) = close(app, CloseWindow(win))
function close(app::Application, exc::CloseWindow)
  (; win) = exc
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
function run(app::Application)
  !isnothing(app.running) && cancel(app.running)
  foreach(map_window, keys(app.renderer.render))
  t0 = time()
  #TODO: Don't access the internal field `impl`.
  # Maybe don't even define a wrapper window manager in AbstractGUI, but rather offer a callback function with an associated state.
  event_loop = @spawn !isempty(active_windows(app)) handle_events(app.wm.impl, t0)
  rendering_loop = @spawn render(app)
  app.running = RunningState(event_loop, rendering_loop)
end

function shutdown(app::Application)
  !isnothing(app.running) && cancel(app.running)
  for win in active_windows(app)
    close(app, win)
  end
  app.running = nothing
end
