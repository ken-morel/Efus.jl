function generate(node::Ast.Block)
    children_exprs = [generate(child) for child in node.children]
    return Expr(:block, children_exprs...)
end
