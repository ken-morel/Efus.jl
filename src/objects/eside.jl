struct ESide <: EObject
    side::Symbol
end
function Base.convert(::Type{ESide}, sym::ESymbol)
    return if sym.value ∈ [:top, :bottom, :left, :right, :center]
        ESide(sym.value)
    else
        throw("$sym is not a valid side")
    end
end
