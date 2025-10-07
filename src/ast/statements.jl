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
Base.@kwdef struct IfBranch <: Statement
    condition::Union{Expression, Nothing}
    block::Block = Block()
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
Base.@kwdef struct If <: Statement
    parent::Union{Statement, Nothing} = nothing
    branches::Vector{IfBranch} = []
end

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
    parent::Union{Statement, Nothing} = nothing
    elseblock::Union{Nothing, Block} = nothing
    iterator::Expression
    iterating::Expression
    block::Block
end


"""
    Base.@kwdef struct ComponentCall <: Statement

A component call, is simply a function call,
it supports splats, and snippets instead of being
defined as functions(as in other constructs),
here they are passed as anonymous function arguments 
to the function being called.

# Syntax

"""
Base.@kwdef struct ComponentCall <: Statement
    parent::Union{Statement, Nothing}
    componentname::Symbol
    arguments::Vector{Tuple{Symbol, Union{Symbol, Nothing}, <:Expression}} = []
    splats::Vector{Symbol} = []
    children::Vector{Statement} = []
    snippets::Vector{Snippet} = []
end

Base.@kwdef struct JuliaBlock <: Statement
    parent::Union{Statement, Nothing}
    code::Julia
end
affiliate!(p::ComponentCall, c::Snippet) = push!(p.snippets, c)
