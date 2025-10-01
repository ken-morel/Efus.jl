function generate(node::Ast.Block, list::Bool = false)
    children_exprs = [generate(child) for child in node.children]
    return if list
        Expr(:vect, children_exprs...)
    else
        Expr(:block, children_exprs...)
    end
end
function generate(node::Ast.InlineBlock)
    children_exprs = [generate(child) for child in node.children]
    return Expr(:vect, children_exprs...)
end

function generate(node::Ast.JuliaBlock)
    return generate(node.code; acceptreactive = false)
end
