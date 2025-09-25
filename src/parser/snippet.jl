function parse_snippet!(p::EfusParser)::Union{Ast.Snippet, AbstractParseError, Nothing}
    return ereset(p) do
        b = current_char(p)
        parse_symbol!(p) != :do && return nothing
        e = current_char(p, -1)
        # collect arguments, name::Type = value, puh, julia.
        params = Vector{Tuple{Symbol, Union{Symbol, Ast.Nil}, Union{Ast.Expression, Ast.Nil}}}()
        ended = false
        while !ended
            skip_spaces!(p)
            name = parse_symbol!(p)
            type = Ast.Nil()
            default = Ast.Nil()
            isnothing(name) && break
            skip_spaces!(p)
            if p.text[p.index] == ':'
                p.text[p.index + 1] != ':' && return EfusSyntaxError(
                    "Invalid type assert",
                    current_char(p, 1)
                )
                p.index += 2
                skip_spaces!(p)
                type = parse_symbol!(p)
                isnothing(type) && return EfusSyntaxError("Missing type assertion type in snippet parameter list", current_char(p, -1))
                skip_spaces!(p)
            end
            if p.text[p.index] == '='
                p.index += 1
                (default, token) = @zig! parse_jlexpressiontilltoken!(p, r",|\n")
                if token == "\n"
                    ended = true
                end
            else
                p.text[p.index] == '\n' && break
            end
            push!(params, (name, type, default))
        end
        code = skip_toblock!(p, [:end])
        isnothing(code) && return EfusSyntaxError("Missing closing end for snippet", b * e)
        (code,) = code
        return Ast.Snippet(code, params)
    end
end
