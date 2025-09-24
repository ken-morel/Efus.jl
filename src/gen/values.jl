generate(value::Ast.AbstractValue) = error("Unsupported generating code for $value")


function generate(value::Ast.LiteralValue)
    return if value.val isa Symbol
        quote
            Symbol($(string(value.val)))
        end
    else
        value.val
    end
end

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
