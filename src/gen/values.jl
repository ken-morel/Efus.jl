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
    # Build the complete expression including delimiters
    complete_expr = if !isnothing(value.delimiters)
        string(value.delimiters[1], value.expr, value.delimiters[2])
    else
        value.expr
    end
    
    return if length(value.reactants) > 0 # it is reactive
        final = Ast.substitute(value) do name
            "getvalue($name)"
        end
        # Reconstruct the complete expression with substituted values
        if !isnothing(value.delimiters)
            final = string(value.delimiters[1], final, value.delimiters[2])
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
        Meta.parse(complete_expr)
    end
end

generate(val::Ast.Numeric) = val.val

generate(val::Ast.Vect) = Expr(:vect, generate.(val.items)...)
