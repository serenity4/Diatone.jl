struct Application
  renderer::Renderer
  wm::WindowManager{XWindowManager,XCBWindow}
end

function Application(; release = false)
  instance, device = Lava.init(; debug = !release, with_validation = !release, instance_extensions = ["VK_KHR_xcb_surface"])

  Application(Renderer(instance, device), WindowManager(XWindowManager()))
end

function Base.show(io::IO, ::MIME"text/plain", app::Application)
  print(io, "Application(", length(app.renderer.frame_cycle), " windows)")
end

function XCBWindow(app::Application, title::AbstractString; screen = current_screen(app.wm.impl), x = 0, y = 0, width = 1800, height = 950, map = false, kwargs...)
  win = XCBWindow(app.wm, title; screen, x, y, width, height, map, kwargs...)
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
render(f, app::Application, win::XCBWindow) = insert!(app.renderer.render, win, f)
