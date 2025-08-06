struct EOrient <: EObject
    orient::Symbol
end
function Base.convert(::Type{EOrient}, val::Symbol)
    return if val ∈ [:v, :vertical]
        EOrient(:vertical)
    elseif val ∈ [:h, :horizontal]
        EOrient(:horizontal)
    else
        throw("$val is not a valid orientation")
    end
end
Base.convert(::Type{EOrient}, val::ESymbol) = convert(EOrient, val.value)
