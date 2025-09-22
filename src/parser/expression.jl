function parse_expression!(p::EfusParser)::Union{AbstractParseError, Ast.AbstractExpression, Nothing}
    expr = nothing
    expr = @zig! expr parse_string!(p)
    !isnothing(expr) && return expr
    expr = @zig! expr parse_geometry!(p)
    !isnothing(expr) && return expr
    return nothing
end
