struct Geometry <: Ast.AbstractValue
    signs::Vector{Char}
    parts::Vector{Vector{Number}}
    units::Vector{Union{Symbol, Nothing}}
end

struct Size{T <: Real} <: Ast.AbstractValue
    x::T
    y::T
    unit::Union{Symbol, Nothing}
    Size(x::T, y::T, unit::Union{Symbol, Nothing} = nothing) where {T} = new{T}(x, y, unit)
end


struct Nil <: Ast.AbstractValue end
