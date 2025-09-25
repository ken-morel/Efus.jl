function parse_expression!(p::EfusParser)::Union{AbstractParseError, Ast.AbstractExpression, Nothing}
    expr = @zig! parse_snippet!(p)
    !isnothing(expr) && return expr
    expr = @zig! parse_string!(p)
    !isnothing(expr) && return expr
    expr = @zig! parse_geometry!(p)
    !isnothing(expr) && return expr
    expr = @zig! parse_juliaexpression!(p)
    !isnothing(expr) && return expr
    expr
    return nothing
end
