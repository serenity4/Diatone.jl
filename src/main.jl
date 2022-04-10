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

function render(app::Application)
  fg = FrameGraph(app)
  while true
    build(fg)
    render(fg)
  end
end

function Lava.FrameGraph(app::Application)
  color = color_attachment(app)
  register(fg.frame, color_attachment(app.renderer.targets))
end
