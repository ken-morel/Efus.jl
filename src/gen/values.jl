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


function generate(value::Ast.Expression; acceptreactive::Bool = true)
    return if length(value.reactants) > 0 # it is reactive
        final = Ast.substitute(value) do name
            "getvalue($name)"
        end
        getter = Meta.parse(final)
        if acceptreactive
            quote
                $(Efus.Reactor){Any}(
                    () -> $(getter),
                    nothing,
                    $(Expr(:vect, keys(value.reactants)...))
                )
            end
        else
            getter
        end
    else
        Meta.parse(value.expr)
    end
end

generate(val::Ast.Numeric) = val.val
