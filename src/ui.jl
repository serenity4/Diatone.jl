mutable struct UserInterface
  wm::XWindowManager
  overlay::UIOverlay{XCBWindow}
  task::Task
  function UserInterface()
    ui = new(XWindowManager(), UIOverlay{XCBWindow}())
    ui.task = @spawn LoopExecution(0.005) begin
      while true
        event = poll_for_event(ui.wm)
        isnothing(event) && break
        process_event(ui.wm, event)
      end
    end
    finalizer(close_windows, ui)
  end
end

function close_windows(ui::UserInterface)
  for win in values(ui.wm.windows)
    close(ui, win)
  end
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

function create_window(ui::UserInterface, title::AbstractString; screen = current_screen(ui.wm), x = 0, y = 0, width = 1800, height = 950, map = true, attributes = [XCB.XCB_CW_BACK_PIXEL], values = [screen.black_pixel], kwargs...)
  win = XCBWindow(ui.wm, title; screen, x, y, width, height, map, attributes, values, kwargs...)
  overlay(ui.overlay, win, [])
  set_callbacks!(ui, win, WindowCallbacks())
  win
end

set_callbacks!(ui::UserInterface, win::XCBWindow, callbacks::WindowCallbacks) = set_callbacks!(ui.wm, win, WindowCallbacks(ui, callbacks))
