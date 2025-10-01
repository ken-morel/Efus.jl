"""
    module Ast

Definition of efus parser Ast nodes.

All nodes are subtypes of AbstractExpression

```
abstract type AbstractExpression end

abstract type AbstractStatement <: AbstractExpression end

abstract type AbstractValue <: AbstractExpression end

abstract type ControlFlow <: AbstractStatement end
```
"""
module Ast

abstract type AbstractExpression end

abstract type AbstractStatement <: AbstractExpression end

abstract type AbstractValue <: AbstractExpression end

abstract type ControlFlow <: AbstractStatement end

"""
    struct Block <: AbstractStatement

An efus code block, containing a list of statements,
it is returned by parser's [IonicEfus.Parser.parse!](@ref) method.
"""
struct Block <: AbstractStatement
    children::Vector{AbstractStatement}
end

"""
    struct Numeric <: AbstractValue

Holds a numeric value, returned by [Meta.parse](@ref).
Can be a plain subtype of [Number](@ref) or 
an expression.

## Examples

- 1
- 1.
- 1.em
- 1_45.45e5em
    |  | | |-multiplication
    |  | |-exponential
    |  |-decimal
    |-number

"""
struct Numeric <: AbstractValue
    val::Union{Number, Expr}
end

"""
    struct Vect <: AbstractValue

Stores an efus vector declatation. A 
vector declaration is simply like a normal 
julia literal, except items are julia 
AbstractValue instances.
For convenience, they also support spanning 
over several lines and trailing commas.

## Examples

- [1, 1_45.45e5em]
- ["ama", :symbol]
- [
  do a::Int
    Foo bar=bar
  end,
]

"""
struct Vect <: AbstractValue
    items::Vector{AbstractValue}
end

"""
    struct InlineBlock <: AbstractValue

Efus InlineBlock rebresents inline ast code, 
represented as a vector of AbstractStatement objects,
which are the statements it contains.

## Examples

- begin
    Label text="Hello world"
    Button c=4
  end
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
The syntaxes are exactly like julia's.
"""
struct LiteralValue <: AbstractValue
    val::Union{Real, String, Char, Symbol}
end

"""
    struct Expression <: AbstractValue

Stores a parsed julia expression as an Expr.
It is used internally in if, for and other
statements for storing expressions.
"""
struct Expression <: AbstractValue
    expr::Any
end

"""
    struct Ionic <: AbstractValue

Stores an ionic expression, with it's 
associated type assertion.

## Examples

- ama
- ama'
- (foo' * bar)::Vector{NTuple{2, Char}}
"""
struct Ionic <: AbstractValue
    expr::Any
    type::Any
end


"""
    Base.@kwdef struct Snippet <: AbstractValue

Holds ast definition for a snippet, which 
simply evaluates to a function which returns 
arguments passed a function.
It holds `.content` which stores their content 
and .params which stores a mapping of 
parameter names to their types, or `nothing`.
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

An efus if statement, containing a vector of [IfBranch](@ref).
Every branch holds a `.condition`, whic may be nothing(for the 
else block), and a `.block`.
The expressions support ionic syntax.

## Examples
- if foo' == bar * 2
  end
"""
Base.@kwdef mutable struct IfStatement <: ControlFlow
    branches::Vector{IfBranch}
    parent::Union{AbstractStatement, Nothing} = nothing
end

"""
    Base.@kwdef mutable struct ForStatement <: ControlFlow

A for statement, containing an iterator expression, iterating 
item, containing block and else block.

## Examples

- for (a, b) in [foo', bar]
  end
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

A braced julia code block in the form of a statement.
The return value of the expression should be either 
nothing, a component, or an AbstractVector containing 
components(or nested vectors).

## Examples

- (c' = 4; c' += 1; components[c])
- (children)

"""
Base.@kwdef mutable struct JuliaBlock <: AbstractStatement
    code::Expression
    parent::Union{AbstractStatement, Nothing} = nothing
end

"""
    struct Location

Represent a symbol or expression location 
in source file.
"""
struct Location
    file::Union{String, Nothing}
    start::Union{Tuple{UInt, UInt}, Nothing}
    stop::Union{Tuple{UInt, UInt}, Nothing}
end


"""
    Base.:*(a::Location, b::Location)

Merges the two locations, to create a new location 
starting at the startpos of the first and ending 
at the endpos of the second.
"""
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

Holds the name, arguments, splats, location and children
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
