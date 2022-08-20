using Diatone, Test, GeometryExperiments
using Accessors: setproperties

include("render.jl")
include("rectangle.jl")

main_task = current_task()

function on_key_pressed(app::Application, details::EventDetails)
    (; win, data) = details
    (; key, modifiers) = data
    kc = KeyCombination(key, modifiers)
    @info "Pressing key $kc"
    if kc ∈ [key"q", key"ctrl+q", key"f4"]
        close(app, win)
        @info "Closing the application."
        execute(finalize, main_task, app)
    end
end

function render_main_window(rg::RenderGraph, image)
    color = attachment_resource(ImageView(image), WRITE)
    graphics = RenderNode(render_area = RenderArea(color.data.view.image.dims...))
    @add_resource_dependencies rg begin
        (color => (0.08, 0.05, 0.1, 1.0))::Color = graphics()
    end
    rectangle = Rectangle([
        PosColor(Vec2(-0.5, 0.5), Arr{Float32}(1.0, 0.0, 0.0)),
        PosColor(Vec2(-0.5, -0.5), Arr{Float32}(0.0, 1.0, 0.0)),
        PosColor(Vec2(0.5, 0.5), Arr{Float32}(1.0, 1.0, 1.0)),
        PosColor(Vec2(0.5, -0.5), Arr{Float32}(0.0, 0.0, 1.0)),
    ])
    render_on_color_attachment(graphics, rg, [rectangle], color)
end

@testset "Diatone.jl" begin
    app = Application()
    win = create_window(app, "Window 1")
    @test length(children_tasks()) == 2
    finalize(app)
    wait(app.finalizer_task)
    @test isempty(app.ui.wm.windows)
    @test isempty(children_tasks())

    app = Application()
    win = create_window(app, "Window 1"; map = false)
    fetch(render(render_main_window, app, win))
    fetch(set_callbacks(app, win, WindowCallbacks(; on_key_pressed = Base.Fix1(on_key_pressed, app))))
    map_window(win)
    Diatone.run(app)
    wait(app.finalizer_task)
    @test isempty(children_tasks())
    @test isempty(app.ui.wm.windows)
end;

GC.gc()
