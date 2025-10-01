"""
    module Ast

Definition of efus parser Ast nodes.
"""
module Ast

abstract type AbstractExpression end

abstract type AbstractStatement <: AbstractExpression end

abstract type AbstractValue <: AbstractExpression end

abstract type ControlFlow <: AbstractStatement end

"""
    struct Block <: AbstractStatement

An efus code block, containing a vector of statements.
"""
struct Block <: AbstractStatement
    children::Vector{AbstractStatement}
end

"""
    struct Numeric <: AbstractValue

contains .val, the result of parsing a 
numeriv value, like 12em, or 12.5
"""
struct Numeric <: AbstractValue
    val::Union{Number, Expr}
end

"""
    struct Vect <: AbstractValue

Stores an efus vector declatation. Like 
julia vector syntax, but seperating efus 
Expressions.
"""
struct Vect <: AbstractValue
    items::Vector{AbstractValue}
end

"""
    struct InlineBlock <: AbstractValue

Stores an list of statements as a value.
Instead of s code block.
"""
struct InlineBlock <: AbstractValue
    children::Vector{AbstractStatement}
    InlineBlock(c::Vector{AbstractStatement}) = new(c)
    """
        InlineBlock(c::Block)

    Constructs an inline block from
    the content of a Block.
    """
    InlineBlock(c::Block) = new(c.children)
end

"""
    struct LiteralValue <: AbstractValue

Stores a julia value, like a string, real, char, or symbol.
"""
struct LiteralValue <: AbstractValue
    val::Union{Real, String, Char, Symbol}
end

"""
    struct Expression <: AbstractValue

Stores a parsed julia expression.
"""
struct Expression <: AbstractValue
    expr::Any
end

"""
    struct Ionic <: AbstractValue

Stores an ionic expression, with it's 
type assertion as a julia expression.
"""
struct Ionic <: AbstractValue
    expr::Any
    type::Any
end


"""
    Base.@kwdef struct Snippet <: AbstractValue

An efus snippet, containing a code block and a dictionary of parameters.
"""
Base.@kwdef struct Snippet <: AbstractValue
    content::Block
    params::Dict{Symbol, Union{Expression, Nothing}}
end


struct IfBranch
    condition::Union{Expression, Nothing}
    block::Block
end

"""
    Base.@kwdef mutable struct IfStatement <: ControlFlow

An efus if statement, containing a vector of branches.
"""
Base.@kwdef mutable struct IfStatement <: ControlFlow
    branches::Vector{IfBranch}
    parent::Union{AbstractStatement, Nothing} = nothing
end

"""
    Base.@kwdef mutable struct ForStatement <: ControlFlow

A for statement, containing an iterator expression, iterating 
item, containing block and else block.
"""
Base.@kwdef mutable struct ForStatement <: ControlFlow
    iterator::Expression
    item::Expression
    block::Block
    elseblock::Union{Block, Nothing} = nothing
    parent::Union{AbstractStatement, Nothing} = nothing
end

"""
    Base.@kwdef mutable struct JuliaBlock <: AbstractStatement

A braced julia code block.
"""
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


"""
    Base.@kwdef mutable struct ComponentCall <: AbstractStatement

Holds the name, arguments, splats, location, parent and children
of a component call.
"""
Base.@kwdef mutable struct ComponentCall <: AbstractStatement
    name::Symbol
    arguments::Vector{ComponentCallArgument}
    splats::Vector{ComponentCallSplat}
    location::Union{Location, Nothing}
    parent::Union{AbstractStatement, Nothing}
    children::Vector{AbstractStatement}
end


end
