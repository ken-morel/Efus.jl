"""
"""
struct SnippetParameter
    name::Symbol
    type::Union{Some, Nothing}
    default::Union{Some, Nothing}
end

"""
    Base.@kwdef struct Snippet <: Statement

Ast definition for a snippet. A snippet
effectively evalueates to an
[`IonicEfus.Snippet`](@ref). I's parameers
are used for typing the generaed snippet.
All the arguments are keyword arguments.

# Example

```julia
header(what::String, aye=5, c)
  <code block>
end

evaluates to something like:
Snippet{
  NamedTuple{(:what, :aye, :c), Tuple{String, Any, Any}}
}(
  (;what::String, aye=5, c) -> <block generate>
)
```
"""
Base.@kwdef struct Snippet <: Statement
    parent::Statement
    name::Symbol
    params::Vector{SnippetParameter}
    block::Block = Block()
end

public Snippet, SnippetParameter

affiliate!(::T, ::Snippet) where {T <: Statement} = error(
    "Error, container of type $T does not support snippets",
)
takesnippetparameters(name::Symbol) = SnippetParameter[SnippetParameter(name, nothing, nothing)]

function takesnippetparameters(expr::Expr)::Vector{SnippetParameter}
    params = SnippetParameter[]
    # This function should handle keyword arguments, which are under the :parameters key
    # for a tuple expression. For now, we assume the args are directly in the tuple.
    if expr.head in (:(=), :(::))
        expr = Expr(:tuple, expr)
    end
    expr.head !== :tuple && error(
        "Expected a tuple of arguments as expr"
    )
    for arg in expr.args
        if arg isa Symbol
            # e.g., `item`
            push!(params, SnippetParameter(arg, nothing, nothing))
            continue
        elseif arg isa Expr
            if arg.head === :(::)
                # e.g., `item::String`
                push!(params, SnippetParameter(arg.args[1], Some(arg.args[2]), nothing))
                continue
            elseif arg.head === :(=)
                # e.g., `index=0` or `item::String="default"`
                value = arg.args[2]
                lhs = arg.args[1]
                if lhs isa Expr && lhs.head === :(::)
                    # `item::String = "default"`
                    name = lhs.args[1]
                    type = lhs.args[2]
                    push!(params, SnippetParameter(name, Some(type), Some(value)))
                    continue
                elseif lhs isa Symbol
                    # `index = 0`
                    push!(params, SnippetParameter(lhs, nothing, Some(value)))
                    continue
                end
            end
        end
        error(
            "Invalid snippet parameters, wrong left hand side to equal, in: $(arg)"
        )
    end
    return params
end
