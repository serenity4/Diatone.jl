mutable struct Application
  renderer::Renderer
  ui::UserInterface
  function Application(; release = false)
    app = new(Renderer(; release), UserInterface())
    finalizer(_shutdown, app)
  end
end

function _shutdown(app::Application)
  tasks = children_tasks()
  shutdown_children()
  @async begin
    ConcurrencyGraph.wait_timeout(all(istaskdone, tasks), 2, 0.001) || @warn "Timeout: Renderer and UI tasks are still alive. Their finalizers will be run but will result in undefined behavior."
    finalize(app.renderer)
    finalize(app.ui)
  end
end

Base.getproperty(app::Application, name::Symbol) = Protected(getfield(app, name))

function active_windows(app::Application)
  ret = ConcurrencyGraph.execute(ui -> deepcopy(ui.wm.windows), app.ui, app.ui)
  iserror(ret) && return XCBWindow[]
  keys(fetch(ret))
end

function Base.show(io::IO, ::MIME"text/plain", app::Application)
  print(io, "Application(", length(active_windows(app)), " windows)")
end

function create_window(app::Application, args...; kwargs...)
  win = fetch(execute(create_window, app.ui, app.ui, args...; kwargs...))
  execute(add_frame_cycle, app.renderer, app.renderer, win)
  win
end

function close(app::Application, win::XCBWindow)
  execute(delete_frame_cycle, app.renderer, app.renderer, win), execute(close, app.ui, app.ui, win)
end

render(f, app::Application, win) = execute(set_render!, app.renderer, f, app.renderer, win)

set_callbacks!(app::Application, win::XCBWindow, callbacks::WindowCallbacks) = execute(set_callbacks!, app.ui, app.ui, win, callbacks)

"""
Wait for the application's event and rendering loops to terminate.

The event loop handles window events via WindowAbstractions.
The rendering loop handles graphics rendering via Lava.
"""
run() = monitor_children(; allow_failures = false)
