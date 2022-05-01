mutable struct UserInterface
  wm::XWindowManager
  overlay::UIOverlay{XCBWindow}
  @atomic task::Optional{SpawnedTask}
end

UserInterface() = UserInterface(XWindowManager(), UIOverlay{XCBWindow}(), nothing)

function start(ui::UserInterface)
  isnothing(ui.task) || error("The UI thread was already started.")
  t0 = time()
  @atomic ui.task = @spawn handle_events(ui.wm, t0; on_iter_last = () -> sleep(0.001))
end

function cancel(ui::UserInterface)
  isnothing(ui.task) && return
  cancel(ui.task)
  @atomic ui.task = nothing
end

check_isrunning(ui::UserInterface) = !isnothing(ui.task) || error("The UI thread has not been started yet.")

function execute(f, ui::UserInterface; kwargs...)
  check_isrunning(ui)
  execute(f, ui.task; kwargs...)
end

function close(ui::UserInterface, win::XCBWindow)
  haskey(ui.overlay.areas, win) && delete!(ui.overlay.areas, win)
  WindowAbstractions.default_on_close(ui.wm, CloseWindow(win))
end

function WindowAbstractions.WindowCallbacks(ui::UserInterface, callbacks::WindowCallbacks)
  callbacks.on_close === WindowAbstractions.default_on_close || error("The callback for `on_close` is reserved.")
  WindowCallbacks(;
      on_close = (wm, ed) -> close(ui, ed.win),
      callbacks.on_invalid,
      callbacks.on_resize,
      callbacks.on_expose,

      # React to all events.
      on_mouse_button_pressed  = ed -> (execute_callback(callbacks, ed); react_to_event(ui.overlay, ed)),
      on_mouse_button_released = ed -> (execute_callback(callbacks, ed); react_to_event(ui.overlay, ed)),
      on_pointer_move          = ed -> (execute_callback(callbacks, ed); react_to_event(ui.overlay, ed)),
      on_pointer_enter         = ed -> (execute_callback(callbacks, ed); react_to_event(ui.overlay, ed)),
      on_pointer_leave         = ed -> (execute_callback(callbacks, ed); react_to_event(ui.overlay, ed)),
      on_key_pressed           = ed -> (execute_callback(callbacks, ed); react_to_event(ui.overlay, ed)),
      on_key_released          = ed -> (execute_callback(callbacks, ed); react_to_event(ui.overlay, ed)),
  )
end
