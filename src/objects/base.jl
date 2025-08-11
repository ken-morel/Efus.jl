struct ESymbol <: EObject
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

struct EBool <: EMirrorObject{Bool}
    value::Bool
end
struct ENothing <: EMirrorObject{Nothing}
    value::Nothing
end

Base.convert(::Type{T} where {T}, val::EMirrorObject{T} where {T})::T where {T} = val.value
Base.convert(::Type{Symbol}, val::ESymbol) = val.value


function Base.convert(::Type{Bool}, val::ESymbol)
    value = string(val.value)
    return if value ∈ ["t", "true"]
        true
    elseif val.value ∈ ["f", "false"]
        false
    else
        throw("$val is not a valid boolean")
    end
end
