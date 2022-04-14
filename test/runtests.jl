using Diatone
using Test

@testset "Diatone.jl" begin
    app = Application()
    win = Window(app, "Window 1")
    render(app, win) do (rg, image)
        # Perform rendering operations.
    end
    close(app, win)
end;
