module Ast
abstract type AbstractExpression end

abstract type AbstractStatement <: AbstractExpression end

abstract type AbstractValue <: AbstractExpression end

abstract type ControlFlow <: AbstractStatement end

struct Block <: AbstractStatement
    children::Vector{AbstractStatement}
end

struct InlineBlock <: AbstractValue
    children::Vector{AbstractStatement}
    InlineBlock(c::Vector{AbstractStatement}) = new(c)
    InlineBlock(c::Block) = new(c.children)
end

struct LiteralValue <: AbstractValue
    val::Union{Real, String, Char, Symbol}
end

struct Expression <: AbstractValue
    expr::String
    reactants::Dict{Symbol, Vector{NTuple{2, UInt}}}
end


Base.@kwdef struct Snippet <: AbstractValue
    content::Block
    params::Dict{Symbol, Union{Expression, Nothing}}
end

struct IfBranch
    condition::Union{Expression, Nothing}
    block::Block
end

Base.@kwdef mutable struct IfStatement <: ControlFlow
    branches::Vector{IfBranch}
    parent::Union{AbstractStatement, Nothing} = nothing
end
Base.@kwdef mutable struct ForStatement <: ControlFlow
    iterator::Expression
    item::Expression
    block::Block
    elseblock::Union{Block, Nothing} = nothing
    parent::Union{AbstractStatement, Nothing} = nothing
end

Base.@kwdef mutable struct JuliaBlock <: AbstractStatement
    code::Expression
    parent::Union{AbstractStatement, Nothing} = nothing
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


end
