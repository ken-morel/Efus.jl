function parse_jlsymbol!(p::EfusParser)::Union{Ast.LiteralValue, AbstractParseError, Nothing}
    return ereset(p) do
        !inbounds(p) && return nothing

        start_char = p.text[p.index]
        start_loc = current_char(p)

        if start_char != ':'
            return nothing
        end

        p.index += 1


        symb = parse_symbol!(p)
        isnothing(symb) &&
            return EfusSyntaxError(p, "Expected symbol after ':'", start_loc * current_char(p))
        return Ast.LiteralValue(symb)
    end
end
function parse_expression!(p::EfusParser)::Union{AbstractParseError, Ast.AbstractExpression, Nothing}
    @zig!r parse_block!(p)
    @zig!r parse_snippet!(p)
    @zig!r parse_string!(p)
    @zig!r parse_jlsymbol!(p)
    @zig!r parse_number!(p)
    @zig!r parse_vect!(p)
    @zig!r parse_fuss!(p)
    return
end
