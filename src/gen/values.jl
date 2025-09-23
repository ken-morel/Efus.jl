generate(value::Ast.AbstractValue) = error("Unsupported generating code for $value")


generate(value::Ast.LiteralValue) = value.val

function generate(value::Ast.Expression)
    if length(value.reactants) > 0 # it is reactive
        final = Ast.substitute(value) do name
            "getvalue($name)"
        end
        getter = Meta.parse(final)

        return quote
            $(Efus.Reactor){Any}(
                () -> $(getter),
                nothing,
                $(Expr(:vect, keys(value.reactants)...))
            )
        end
    else
        return Meta.parse(value.expr)
    end
end

generate(value::Efus.Size) = value

generate(value::Efus.Geometry) = value
