module Ast
abstract type AbstractStatement end
abstract type AbstractExpression end

abstract type AbstractValue <: AbstractExpression end

struct LiteralValue <: AbstractValue
    val::Union{Real, String, Char}
end

struct Expression <: AbstractValue
    expr::String
    reactants::Dict{Symbol, Vector{NTuple{2, UInt}}}
end

function substitute(fn::Function, expr::Expression)::String
    text = expr.expr
    replaces = Vector{Tuple{UInt, UInt, String}}()
    for (name, positions) in expr.reactants
        value = fn(name)
        for (start, stop) in positions
            push!(replaces, (start, stop, value))
        end
    end
    sort!(replaces)
    reverse!(replaces)
    for (start, stop, txt) in replaces
        text = (
            prevind(text, start) > 0 ? text[begin:prevind(text, start)] : ""
        ) * txt * (
            nextind(text, stop) <= length(text) ? text[nextind(text, stop):end] : ""
        )
    end
    return text
end

struct Location
    file::Union{String, Nothing}
    start::Union{Tuple{UInt, UInt}, Nothing}
    stop::Union{Tuple{UInt, UInt}, Nothing}
end


Base.:*(a::Location, b::Location) = Location(a.file, a.start, b.stop)

Base.@kwdef struct ComponentCallArgument
    name::Symbol
    value::AbstractValue
    location::Location
end

struct ComponentCallSplat <: AbstractStatement
    name::Symbol
    location::Location
end


Base.@kwdef mutable struct ComponentCall <: AbstractStatement
    name::Symbol
    arguments::Vector{ComponentCallArgument}
    splats::Vector{ComponentCallSplat}
    location::Union{Location, Nothing}
    parent::Union{AbstractStatement, Nothing}
    children::Vector{AbstractStatement}
end

struct Block <: AbstractStatement
    children::Vector{AbstractStatement}
end


end
