function generate(node::Ast.AbstractStatement)
    error("Generation not implemented for this node type: $(typeof(node))")
end


function generate(node::Ast.ComponentCall)
    # literally: not all children are ComponentCalls
    shouldflatten = !all(isa.(node.children, Ast.ComponentCall))
    shouldfilter = any(isa.(node.children, Ast.JuliaCode))

    kwargs = [Expr(:kw, arg.name, generate(arg.value)) for arg in node.arguments]

    splats = [Expr(:..., splat.name) for splat in node.splats]

    children_exprs = [generate(child) for child in node.children]

    if !isempty(children_exprs)
        children = Expr(:vect, children_exprs...)
        if shouldfilter
            children = quote
                filter!(!isnothing, $children)
            end
        end
        if shouldflatten
            children = quote
                convert.($(Efus.AbstractComponent), Iterators.flatten($children))
            end
        end
        children_kw = Expr(:kw, :children, children)
        push!(kwargs, children_kw)
    end

    return Expr(:call, node.name, splats..., kwargs...)
end
