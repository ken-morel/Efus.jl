function generate(fuss::Ast.Ionic)
    expr, dependencies = Ionic.translate(fuss.expr)
    type = something(Ionic.translate(fuss.type)[1], Any)

    return if isempty(dependencies)
        Expr(:(::), expr, type)
    else
        quote
            $(Efus.Reactor){$type}(
                () -> $expr,
                nothing,
                $(Expr(:vect, dependencies...))
            )
        end
    end
end
