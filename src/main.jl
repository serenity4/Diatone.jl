#=

- 1 thread to handle window events via WindowAbstractions.
- 1 thread to handle rendering with Lava.

=#

function main(app)
  event_loop = Threads.@spawn run(app)
  rendering_loop = Threads.@spawn render(app)
  wait(event_loop)
  wait(rendering_loop)
end
