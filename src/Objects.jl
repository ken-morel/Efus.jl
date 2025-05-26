abstract type EObject end
abstract type AbstractNamespace <: EObject end
resolve(obj::EObject, _::Union{AbstractNamespace,Nothing}=nothing) = obj
abstract type EMirrorObject <: EObject end
resolve(obj::EMirrorObject, _::Union{AbstractNamespace,Nothing}=nothing) = obj.value

struct EInt <: EMirrorObject
  value::Int
end
struct EDecimal <: EMirrorObject
  value::Float32
end
struct EString <: EMirrorObject
  value::String
end

