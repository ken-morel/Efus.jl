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

generate(val::Ast.Expression) = val.expr

generate(val::Ast.Numeric) = val.val

generate(val::Ast.Vect) = Expr(:vect, generate.(val.items)...)
