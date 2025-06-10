struct EOrient <: EObject
  orient::Symbol
end
function Base.convert(::Type{EOrient}, val::ESymbol)
  if val.value ∈ [:v, :vertical]
    EOrient(:vertical)
  elseif val.value ∈ [:h, :horizontal]
    EOrient(:horizontal)
  else
    throw("$val is not a valid orientation")
  end
end
