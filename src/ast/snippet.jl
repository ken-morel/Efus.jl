"""
    Base.@kwdef struct Snippet <: Statement

Ast definition for a snippet. A snippet
effectively evalueates to an
[`Efus.Snippet`](@ref). It's simply an anonymous
function which contains more efus code.

# Example

```julia
header(what::String, aye=5, c)
  <code block>
end
```
"""
Base.@kwdef mutable struct Snippet <: Statement
    parent::Statement
    name::Symbol
    params::Union{Reactor,Julia}
    block::Block = Block()
    tokens::@NamedTuple{name::Tokens.Token}
    endtoken::Union{Tokens.Token,Nothing} = nothing
end

public Snippet

affiliate!(::T, ::Snippet) where {T<:Statement} =
    error("Error, container of type $T does not support snippets")
