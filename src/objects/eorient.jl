struct EOrient <: EObject
    orient::Symbol
end
function Base.convert(::Type{EOrient}, val::Symbol)
    return if val ∈ [:v, :vertical]
        EOrient(:vertical)
    elseif val ∈ [:h, :horizontal]
        EOrient(:horizontal)
    elseif val ∈ [:b, :both]
        EOrient(:both)
    elseif val ∈ [:n, :none]
        EOrient(:none)
    else
        throw("$val is not a valid orientation")
    end
end
Base.convert(::Type{EOrient}, val::ESymbol) = convert(EOrient, val.value)
