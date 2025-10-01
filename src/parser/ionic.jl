function parse_ionic!(p::EfusParser)::Union{Ast.Ionic, AbstractParseError, Nothing}
    return ereset(p) do
        start = current_char(p)
        name = parse_symbol!(p)
        if !isnothing(name)
            if inbounds(p) && p.text[p.index] == '''
                p.index += 1
                return Ast.Ionic(Expr(Symbol("'"), name), nothing)
            else
                @zig! eoe(p, "In julia expression")

                !isnothing(name) && return Ast.Ionic(name, nothing)
            end
        end

        if p.text[p.index] == '('
            txt = @zig! skip_julia!(p, nothing)
            code = try
                Meta.parse(txt)
            catch e
                return EfusSyntaxError(p, "Invalid julia expression: $(e.msg)", current_char(p))
            end
            type = if inbounds(p) && p.text[p.index] == ':' # A type assert
                p.index += 1
                !inbounds(p) || p.text[p.index] != ':' && return EfusSyntaxError(p, "Invalid type assert", current_char(p))
                p.index += 1
                try
                    type_expr = Meta.parse(@zig! skip_julia!(p, r" |\n|,"))
                catch e
                    return EfusSyntaxError(p, "Invalid type in type assert: $(e.msg)", current_char(p))
                else
                    p.index -= 1
                    type_expr
                end
            end

            return Ast.Ionic(code, type)
        end
    end
end
