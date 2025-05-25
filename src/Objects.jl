abstract type EObject end
abstract type EMirrorObject <: EObject end
abstract type AbstractNamespace end

struct EInt <: EMirrorObject
  value::Int
end
struct EDecimal <: EMirrorObject
  value::Float32
end
struct EString <: EMirrorObject
  value::String
end


