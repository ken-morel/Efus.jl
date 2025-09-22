function generate(node::Ast.AbstractStatement)
    error("Generation not implemented for this node type: $(typeof(node))")
end


function generate(node::Ast.ComponentCall)
    kwargs = [Expr(:kw, arg.name, generate(arg.value)) for arg in node.arguments]

    splats = [Expr(:..., splat.name) for splat in node.splats]

    children_exprs = [generate(child) for child in node.children]

    if !isempty(children_exprs)
        children_kw = Expr(:kw, :children, Expr(:vect, children_exprs...))
        push!(kwargs, children_kw)
    end

    return Expr(:call, node.name, splats..., kwargs...)
end
