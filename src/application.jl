const ApplicationState = Nothing

struct Application
  instance::Lava.Instance
  device::Lava.Device
  wm::WindowManager{XWindowManager,XCBWindow}
  swapchains::Dictionary{XCBWindow, Swapchain{XCBWindow}}
  widgets::Dictionary{XCBWindow, Any}
  state::ApplicationState
end

function Application(; release = false)
  instance, device = Lava.init(; debug = !release, with_validation = !release, instance_extensions = ["VK_KHR_xcb_surface"])

  Application(instance, device, XWindowManager(), Dictionary(), ApplicationState())
end

function new_window(app::Application, title::AbstractString; screen = current_screen(wm), x = 0, y = 0, width = 1800, height = 950, kwargs...)
  win = new_window(app.wm, title; screen, x, y, width, height, kwargs...)
  surface = xcb_surface(instance, win)
  isnothing(app.device.queues.present_queue) && set_presentation_queue(device, [surface])
  swapchain = Swapchain(app.device, surface, Vk.IMAGE_USAGE_COLOR_ATTACHMENT_BIT)
  set_callbacks!(app.wm, win, WindowCallbacks(on_close = Base.Fix1(close_window, app)))
  insert!(app.swapchains, win, swapchain)
  win
end

function xcb_surface(instance, win::XCBWindow)
  handle = unwrap(Vk.create_xcb_surface_khr(instance, Vk.XcbSurfaceCreateInfoKHR(win.conn.h, win.id)))
  Surface(handle, win)
end

function close_window(app::Application, exc::CloseWindow)
  (; win) = exc
  empty!(app.widgets[win])
  swapchain = app.swapchains[win]
  delete!(app.swapchains, win)

  # Can wait for rendering to finish first if it causes issues.
  finalize(swapchain.handle)
  finalize(swapchain.surface.handle)

  WindowAbstractions.default_on_close(app.wm, exc)
end
