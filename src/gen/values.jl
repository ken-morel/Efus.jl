generate(value::Ast.AbstractValue) = error("Unsupported generating code for $value")


generate(value::Ast.LiteralValue) = value.val

generate(value::Ast.Expression) = Meta.parse(value.expr)

generate(value::Efus.Size) = value

generate(value::Efus.Geometry) = value
