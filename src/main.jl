#=

- 1 thread to handle window events via WindowAbstractions.
- 1 thread to handle rendering with Lava.

=#

function run(app::Application)
  event_loop = Threads.@spawn run(app.wm)
  rendering_loop = Threads.@spawn render(app)
  wait(event_loop)
  wait(rendering_loop)
end
