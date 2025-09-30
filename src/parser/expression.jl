function parse_expression!(p::EfusParser)::Union{AbstractParseError, Ast.AbstractExpression, Nothing}
    @zig!r parse_block!(p)
    @zig!r parse_snippet!(p)
    @zig!r parse_string!(p)
    @zig!r parse_number!(p)
    @zig!r parse_vect!(p)
    @zig!r parse_juliaexpression!(p)
    return
end
