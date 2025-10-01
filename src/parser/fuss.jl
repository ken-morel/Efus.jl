function parse_fuss!(p::EfusParser)::Union{Ast.Fuss, AbstractParseError, Nothing}
    return ereset(p) do
        start = current_char(p)
        name = parse_symbol!(p)
        if !isnothing(name)
            if inbounds(p) && p.text[p.index] == '''
                # Calculate position relative to the start of the expression
                expr_start = start.start[2]  # Character position from the location
                pos = (1, p.index - expr_start + 1) .|> UInt
                p.index += 1
                # Check if we're at the end of the string or at whitespace
                if !inbounds(p) || isspace(p.text[p.index])
                    return Ast.Fuss(Expr(Symbol("'"), name), nothing)
                else
                    if inbounds(p)
                        return EfusSyntaxError("Unexpected token after reactive variable", current_char(p))
                    else
                        return EfusSyntaxError("Unexpected end of input after reactive variable", start)
                    end
                end
            else
                @zig! eoe(p, "In julia expression")

                !isnothing(name) && return Ast.Fuss(name, nothing)
            end
        end
        if p.text[p.index] == ':'
            p.index += 1
            name = parse_symbol!(p)
            isnothing(name) && return EfusSyntaxError("Invalid julia Symbol at pos", start * current_char(p))
            return Ast.LiteralValue(name)
        elseif p.text[p.index] == '('
            txt = @zig! skip_julia!(p, nothing)
            println(repr(txt))
            code = try
                Meta.parse(txt)
            catch e
                return EfusSyntaxError("Invalid julia expression: $(e.msg)", current_char(p))
            end
            type = if inbounds(p) && p.text[p.index] == ':' # A type assert
                p.index += 1
                !inbounds(p) || p.text[p.index] != ':' && return EfusSyntaxError("Invalid type assert", current_char(p))
                p.index += 1
                try
                    Meta.parse(@zig! skip_julia!(p, r".*"))
                catch e
                    return EfusSyntaxError("Invalid type in type assert: $(e.msg)", current_char(p))
                end
            end
            return Ast.Fuss(code, type)
        end
    end
end
