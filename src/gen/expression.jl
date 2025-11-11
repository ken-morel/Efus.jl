"""
    generate(expr::Ast.Julia)

Generates a valid julia expr from the
passed ast expression by taking the 
output of [`Ionic.transcribe`](@ref).
"""
generate(expr::Ast.Julia) = Ionic.transcribe(expr.expr).code


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
    trans = Ionic.transcribe(expr.expr)
    type = something(Ionic.transcribe(expr.type).code, :Any)
    dependencies_expr = Expr(:ref, Efus.AbstractReactive, trans.gets...)
    return quote
        $(Ionic.Reactor){$type}(() -> $(trna.code), nothing, $dependencies_expr)
    end
end

"""
    generate(expr::Ast.Vect)

Generates an efus vector, simply by
generating the vect items and wrapping in a
:vect. Like `Expr(:vect, generate.(expr.items)...)`
"""
generate(expr::Ast.Vect) = Expr(:vect, generate.(expr.items)...)

"""
    generate(expr::Ast.Arrow)

Generates a julia arrow function from
[`Ast.Arrow`](@ref).
"""
function generate(expr::Ast.Arrow)
    params = if expr.params isa Ast.Julia
        generate(expr.params)
    else
        Efus.transcribe(Expr(:(::), expr.params.expr, expr.params.type)).code
    end
    return Expr(:->, params, generate(expr.body))
end
