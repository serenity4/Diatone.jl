struct Application
  renderer::Renderer
  ui::UserInterface
end

function Application(; release = false)
  Application(Renderer(; release), UserInterface())
end

active_windows(app::Application) = keys(app.renderer.render)

function Base.show(io::IO, ::MIME"text/plain", app::Application)
  print(io, "Application(", length(active_windows(app)), " windows)")
end

function XCBWindow(app::Application, title::AbstractString; screen = current_screen(app.ui.wm), x = 0, y = 0, width = 1800, height = 950, map = false, attributes = [XCB.XCB_CW_BACK_PIXEL], values = [screen.black_pixel], kwargs...)
  @execute_maybe_on app.ui win = begin
    win = XCBWindow(app.ui.wm, title; screen, x, y, width, height, map, attributes, values, kwargs...)
    overlay(app.ui.overlay, win, [])
    set_callbacks!(app, win, WindowCallbacks())
    win
  end
  @execute_maybe_on app.renderer add_frame_cycle(app.renderer, win)
  win
end

function set_callbacks!(app::Application, win::XCBWindow, callbacks::WindowCallbacks)
  @execute_maybe_on app.ui set_callbacks!(app.ui.wm, win, WindowCallbacks(app.ui, callbacks))
end

function close(app::Application, win::XCBWindow)
  @execute_maybe_on app.ui close(app.ui, win)
  @execute_maybe_on app.renderer delete_frame_cycle(app.renderer, win)
end

function render(f, app::Application, win::XCBWindow)
  @execute_maybe_on app.renderer set!(app.renderer.render, win, f)
end

render(app::Application) = @execute_maybe_on app.renderer render(app.renderer)

"""
Run the application's event and rendering loops.

The event loop handles window events via WindowAbstractions.
The rendering loop handles graphics rendering via Lava.
"""
function run(app::Application; wait = true)
  start(app.ui)
  start(app.renderer)
  wait && Diatone.wait(app)
  nothing
end

function wait(app::Application)
  wait_all(app.ui, app.renderer) || shutdown(app)
end

function shutdown(app::Application)
  cancel(app.ui)
  cancel(app.renderer)
  for win in active_windows(app)
    close(app, win)
  end
end
