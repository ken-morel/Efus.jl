abstract type EObject end
abstract type AbstractNamespace <: EObject end
resolve(obj::EObject, _::Union{AbstractNamespace,Nothing}=nothing) = obj
abstract type EMirrorObject{T} <: EObject end
resolve(obj::EMirrorObject{T} where T, _::Union{AbstractNamespace,Nothing}=nothing)::T where T = obj.value

struct EInt <: EMirrorObject{Int}
  value::Int
end
struct EDecimal <: EMirrorObject{Float32}
  value::Float32
end
struct EString <: EMirrorObject{String}
  value::String
end
struct ESize{T,U} <: EObject
  value::Tuple{T,T}
  unit::Val{U}
  ESize(size::Tuple{T,T}, unit::Union{Symbol,Nothing}=nothing) where T = new{T,unit}(size, Val(unit))
end
unit(s::ESize)::Union{Symbol,Nothing} = typeof(s.unit).parameters[2] #TODO: Improve this

