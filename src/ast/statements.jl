affiliate!(c::Statement) = !isnothing(c.parent) ? affiliate!(c.parent, c) : nothing
affiliate!(p::Statement, c::Statement) = push!(p.children, c)

"""
    Base.@kwdef struct IfBranch <: Statement

Holds a branch of an if statement, 
with it's `.condition` Expression and associated
`.block`, else blocks have a `nothing` 
condition.

See also [`Expression`](@ref), [`Block`](@ref), [`If`](@ref).
"""
Base.@kwdef mutable struct IfBranch <: Statement
    condition::Union{Expression,Nothing}
    block::Block = Block()
    tokens::Union{@NamedTuple{keyword::Tokens.Token},Nothing} = nothing
end
affiliate!(p::IfBranch, c::Statement) = affiliate!(p.block, c)

"""
    Base.@kwdef struct If <: Statement

An if statement is simply represented as a vector 
of [`IfBranch`](@ref) s.
If statement condition supports ionic syntax.

# Syntax

```julia
if [condition]
  <codeblock>
elseif [condition]
  <codeblock>
else
  <codeblock>
end
```
"""
Base.@kwdef mutable struct If <: Statement
    parent::Union{Statement,Nothing} = nothing
    branches::Vector{IfBranch} = []
    tokens::Union{NamedTuple{},Nothing} = nothing
    endtoken::Union{Tokens.Token,Nothing} = nothing
end
public If

"""
    Base.@kwdef mutable struct For <: Statement

A for statement converts either to a julia 
list comprehension, or to an if block checking
if the vector is empty, for statements also supports
ionic statements, and since it converts to an actual 
for, also supports destructuring.

# Examples

```julia
for (key, value) in mydict
  <codeblock>
else # optional
  <codeblock>
end
```
"""
Base.@kwdef mutable struct For <: Statement
    parent::Union{Statement,Nothing} = nothing
    elseblock::Union{Nothing,Block} = nothing
    elsetoken::Union{Tokens.Token,Nothing} = nothing
    iterator::Expression
    iterating::Expression
    block::Block
    tokens::Union{@NamedTuple{keyword::Tokens.Token,inkeyword::Tokens.Token},Nothing} =
        nothing
    endtoken::Union{Tokens.Token,Nothing} = nothing
end
public For


"""
    Base.@kwdef struct ComponentCall <: Statement

A component call, is simply a function call,
it supports splats, and snippets instead of being
defined as functions(as in other constructs),
here they are passed as anonymous function arguments 
to the function being called.

# Syntax

```julia
  Foo.Label text="Hello world" args...
#    |          |               |
#    |          |              splats
#    |          |
#    |        Argument=value
#    |
# Function name/path
```
"""
Base.@kwdef struct ComponentCall <: Statement
    parent::Union{Statement,Nothing}
    componentname::Union{Expr,Symbol}
    arguments::Vector{
        @NamedTuple{
            name::Symbol,
            sub::Union{Symbol,Nothing},
            value::Expression,
            tokens::Union{
                @NamedTuple{name::Tokens.Token,sub::Union{Tokens.Token,Nothing}},
                Nothing,
            },
        }
    } = []
    splats::Vector{Symbol} = []
    children::Vector{Statement} = []
    snippets::Vector{Snippet} = []
    tokens::@NamedTuple{name::Vector{Tokens.Token}}
end
public ComponentCall


"""
    Base.@kwdef struct JuliaBlock <: Statement

Represents a block of julia code acting as
a statement, it is internally represented as
a [`Ast.Julia`](@ref) and has no child,
it is passed through [`Ionic.transcribe`](@ref).

# Syntax
```julia
(My+julia-expr;)
```
"""
Base.@kwdef mutable struct JuliaBlock <: Statement
    parent::Union{Statement,Nothing}
    code::Julia
    tokens::Union{@NamedTuple{code::Tokens.Token},Nothing} = nothing
end

public JuliaBlock
affiliate!(p::ComponentCall, c::Snippet) = push!(p.snippets, c)
