generate(expr::Ast.Julia) = Ionic.transcribe(expr.expr)[1]


function generate(expr::Ast.Reactor)
    getter, dependencies = Ionic.transcribe(expr.expr)
    type = something(Ionic.transcribe(expr.type)[1], :Any)
    dependencies_expr = Expr(:ref, IonicEfus.AbstractReactive, dependencies...)
    return quote
        $(IonicEfus.Reactor){$type}(
            () -> $getter,
            nothing,
            $dependencies_expr,
        )
    end
end

function generate(expr::Ast.Vect)
    return Expr(:vect, generate.(expr.items)...)
end
