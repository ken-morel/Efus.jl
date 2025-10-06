function generate(expr::Ast.Julia)
    return expr.value
end

function generate(expr::Ast.Ionic)
    getter, dependencies = Ionic.transcribe(expr.expr)
    type = Ionic.transcribe(expr.type)[1]
    dependencies_expr = Expr(:vect, dependencies...)
    return quote
        $(IonicEfus.Reactor){$(type)}(
            () -> $getter,
            nothing,
            dependencies_expr,
        )
    end
end

function generate(expr::Ast.Vect)
    return Expr(:vect, generate.(expr)...)
end
