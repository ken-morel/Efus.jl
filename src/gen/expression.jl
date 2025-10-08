"""
    generate(expr::Ast.Julia)

Generates a valid julia expr from the
passed ast expression by taking the 
output of [`IonicEfus.transcribe`](@ref).
"""
generate(expr::Ast.Julia) = Ionic.transcribe(expr.expr)[1]


"""
    generate(expr::Ast.Reactor)

Generates a lazy reactor definition from
the expression and typeassert of the passed
reactor ast. It gets the dependencies from
the return of Ionic.transcribe which is applied
both on the getter, and the type
The generated reactor has just a getter and
dependencies.
```
"""
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

"""
    generate(expr::Ast.Vect)

Generates an efus vector, simply by
generating the vect items and wrapping in a
:vect. Like `Expr(:vect, generate.(expr.items)...)`
"""
generate(expr::Ast.Vect) = Expr(:vect, generate.(expr.items)...)
