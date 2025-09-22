module Ast
abstract type AbstractStatement end
abstract type AbstractExpression end

abstract type AbstractValue <: AbstractExpression end

struct LiteralValue <: AbstractValue
    val::Union{Real, String, Char}
end

struct Expression <: AbstractValue
    expr::String
end

struct Location
    file::Union{String, Nothing}
    start::Union{Tuple{UInt, UInt}, Nothing}
    stop::Union{Tuple{UInt, UInt}, Nothing}
end


Base.:*(a::Location, b::Location) = Location(a.file, a.start, b.stop)

Base.@kwdef struct ComponentCallArgument
    name::Symbol
    value::Any
    location::Location
end

Base.@kwdef struct ComponentCall <: AbstractStatement
    name::Symbol
    arguments::Vector{ComponentCallArgument}
    location::Union{Location, Nothing}
end

struct Block
    children::Vector{AbstractStatement}
end


end
