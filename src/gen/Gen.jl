module Gen
using ..Ast

function generate(node::Ast.AbstractStatement)
    error("Generation not implemented for this node type: $(typeof(node))")
end

function generate(node::Ast.Block)
    # For a block, we generate a `begin ... end` block containing
    # the code for all its children.
    children_exprs = [generate(child) for child in node.children]
    return Expr(:block, children_exprs...)
end

function generate(node::Ast.ComponentCall)
    kwargs = [Expr(:kw, arg.name, generate(arg.value)) for arg in node.arguments]

    splats = [Expr(:..., splat.name) for splat in node.splats]

    children_exprs = [generate(child) for child in node.children]

    # If there are children, create a `children=[...]` keyword argument
    if !isempty(children_exprs)
        children_kw = Expr(:kw, :children, Expr(:vect, children_exprs...))
        push!(kwargs, children_kw)
    end

    return Expr(:call, node.name, splats..., kwargs...)
end

# We need to generate code for values, too.
function generate(value::Ast.LiteralValue)
    return value.val
end

function generate(value::Ast.Expression)
    return Meta.parse(value.expr)
end

end # module Gen

