const ApplicationState = Nothing

struct Application
  renderer::Renderer
  wm::WindowManager{XWindowManager,XCBWindow}
  widgets::Dictionary{XCBWindow, Any}
  state::ApplicationState
end

function Application(; release = false)
  instance, device = Lava.init(; debug = !release, with_validation = !release, instance_extensions = ["VK_KHR_xcb_surface"])

  Application(instance, device, XWindowManager(), Dictionary(), ApplicationState())
end

function new_window(app::Application, title::AbstractString; screen = current_screen(wm), x = 0, y = 0, width = 1800, height = 950, kwargs...)
  win = new_window(app.wm, title; screen, x, y, width, height, kwargs...)
  set_callbacks!(app.wm, win, WindowCallbacks(on_close = Base.Fix1(close_window, app)))
  add_frame_cycle(app.renderer, win)
  win
end

function close_window(app::Application, exc::CloseWindow)
  (; win) = exc
  empty!(app.widgets[win])
  delete_frame_cycle(app.renderer, win)
  WindowAbstractions.default_on_close(app.wm, exc)
end

function render(app::Application)
  for window in active_windows(app.wm)
    #TODO: Only render new/invalidated widgets to improve performance.
    objects = app.widgets[window]
  end
end
