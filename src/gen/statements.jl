function generate(node::Ast.AbstractStatement)
    error("Generation not implemented for this node type: $(typeof(node))")
end

function cleanchildren(children::Vector)
    children isa Vector{<:Efus.AbstractComponent} && return children
    final = Efus.AbstractComponent[]
    for child in children
        if child isa Efus.AbstractComponent
            push!(final, child)
        elseif child isa AbstractVector
            append!(final, cleanchildren(child))

        elseif !isnothing(child)
            error(
                "Component was passed an unexpected child of type" *
                    " $(typeof(child)): $child" *
                    "make sure it either returns a component, " *
                    "a vector of components or nothing"
            )
        end
    end
    return final
end

function generate(node::Ast.ComponentCall)
    # literally: not all children are ComponentCalls
    shouldclean = !all(isa.(node.children, Ast.ComponentCall))

    kwargs = [Expr(:kw, arg.name, generate(arg.value)) for arg in node.arguments]

    splats = [Expr(:..., splat.name) for splat in node.splats]

    children_exprs = [generate(child) for child in node.children]

    if !isempty(children_exprs)
        children = Expr(:vect, children_exprs...)
        if shouldclean
            children = Expr(:call, cleanchildren, children)
        end
        children_kw = Expr(:kw, :children, children)
        push!(kwargs, children_kw)
    end

    return Expr(:call, node.name, splats..., kwargs...)
end
