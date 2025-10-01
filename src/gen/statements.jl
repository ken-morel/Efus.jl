function generate(node::Ast.ComponentCall)
    # literally: not all children are ComponentCalls
    shouldclean = !all(isa.(node.children, Ast.ComponentCall))

    kwargs = [Expr(:kw, arg.name, generate(arg.value)) for arg in node.arguments]

    splats = Expr(:parameters, [Expr(:..., splat.name) for splat in node.splats]...)

    children_exprs = [generate(child) for child in node.children]

    if !isempty(children_exprs)
        children = Expr(:vect, children_exprs...)
        if shouldclean
            children = Expr(:|>, children, IonicEfus.cleanchildren)
        end
        children_kw = Expr(:kw, :children, children)
        push!(kwargs, children_kw)
    end
    return Expr(:call, node.name, splats, kwargs...)
end
