struct ESymbol <: EMirrorObject{Symbol}
  value::Symbol
end
struct EInt <: EMirrorObject{Int}
  value::Int
end
struct EDecimal <: EMirrorObject{Float32}
  value::Float32
end
struct EString <: EMirrorObject{String}
  value::String
end
Base.convert(::Type{String}, val::ESymbol) = string(val.value)
Base.convert(::Type{Symbol}, val::ESymbol) = val.value

function Base.convert(::Type{Bool}, val::ESymbol)
  if val.value ∈ [:t, :true]
    true
  elseif val.value ∈ [:f, :false]
    false
  else
    throw("$val is not a valid boolean")
  end
end
