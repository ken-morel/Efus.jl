function generate(ionic::Ast.Ionic)
    expr, dependencies = Ionic.translate(ionic.expr)
    type = something(Ionic.translate(ionic.type)[1], Any)

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
