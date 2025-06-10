abstract type EObject end
abstract type AbstractNamespace <: EObject end
resolve(obj::EObject, _::Union{AbstractNamespace,Nothing}=nothing) = obj
abstract type EMirrorObject{T} <: EObject end
resolve(obj::EMirrorObject{T} where T, _::Union{AbstractNamespace,Nothing}=nothing)::T where T = obj.value
Base.eval(obj::EObject, ::AbstractNamespace) = resolve(obj)
include("objects/egeometry.jl")
include("objects/base.jl")
include("objects/eside.jl")
include("objects/eorient.jl")
include("objects/eexpr.jl") # expr and namebinding
include("objects/ealign.jl")
# composite
include("objects/esize.jl")
include("objects/eedgeinsets.jl")


include("objects/esquaregeometry.jl")
