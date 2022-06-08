struct Protected{T}
  inner::T
end

Base.getproperty(::Protected, ::Symbol) = error("Accessing a field of a protected structure is forbidden.")
Base.setproperty!(::Protected, ::Symbol, ::Any...) = error("Setting a field of a protected structure is forbidden.")

task(prot::Protected) = task(unwrap_protected(prot))
task(x) = x.task

unwrap_protected(prot::Protected) = getfield(prot, :inner)
unwrap_protected(x) = x

execute(args...; kwargs...) = unwrap(ConcurrencyGraph.execute(args...; kwargs...))
fetch(args...; kwargs...) = unwrap(Base.fetch(args...; kwargs...))

ConcurrencyGraph.execute(f, prot::Protected, args...; kwargs...) = ConcurrencyGraph.execute(f, unwrap_protected(prot), unwrap_protected.(args)...; kwargs...)
ConcurrencyGraph.execute(f, x::Union{Renderer,UserInterface}, args...; kwargs...) = ConcurrencyGraph.execute(f, task(x), args...; kwargs...)
