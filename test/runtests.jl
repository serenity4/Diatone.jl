using Diatone, Dictionaries, GeometryExperiments, Lava, SPIRV, Test, XCB

include("render.jl")
include("rectangle.jl")

function on_key_pressed(app, details::EventDetails)
    (; win, data) = details
    (; key, modifiers) = data
    kc = KeyCombination(key, modifiers)
    @info "Pressing key $kc"
    if kc ∈ [key"q", key"ctrl+q", key"f4"]
        close(app, win)
    end
end

function render_main_window(rg::RenderGraph, image)
    color = Attachment(View(image), WRITE)
    color = PhysicalAttachment(color)
    graphics = RenderNode(render_area = Lava.RenderArea(Lava.dims(color)...)) do rec
        rectangle = Rectangle(Point(0.0, 0.0), Box(Scaling(0.2f0, 0.3f0)), (0.5, 0.5, 0.9, 1.0))
        render_on_color_attachment(rec, rg.device, [rectangle], color)
    end
    @add_resource_dependencies rg begin
        (color => (0.01, 0.02, 0.05, 1.0))::Color = graphics()
    end
end

@testset "Diatone.jl" begin
    renderer = Diatone.Renderer()
    ui = Diatone.UserInterface()

    # # For some reason it blocks for a while.
    # @testset "Concurrency utilities" begin
    #     for thread in (renderer, ui)
    #         Diatone.start(thread)
    #         @test Diatone.isrunning(thread)
    #         @test Diatone.@execute(thread, x = 1 + 1) == 2
    #         cancel(thread)
    #         @test !Diatone.isrunning(thread)
    #     end
    # end

    app = Application(renderer, ui)
    win = Window(app, "Window 1")
    render(render_main_window, app, win)
    set_callbacks!(app, win, WindowCallbacks(; on_key_pressed = Base.Fix1(on_key_pressed, app)))
    # map_window(win)

    run(app)
    # run(app; wait = false)
    # sleep(5)
    # t = time()
    # while time() < t + 1.0 end
    shutdown(app)
end;
