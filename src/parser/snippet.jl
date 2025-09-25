function parse_snippet!(p::EfusParser)::Union{Ast.Snippet, AbstractParseError, Nothing}
    return ereset(p) do
        b = current_char(p)
        parse_symbol!(p) != :do && return nothing
        e = current_char(p, -1)
        # collect arguments, name::Type = value, puh, julia.
        params = Dict{Symbol, Union{Ast.Expression, Nothing}}()
        ended = false
        while !ended
            skip_spaces!(p)
            name = parse_symbol!(p)
            type = nothing
            isnothing(name) && break
            skip_spaces!(p)
            params[name] = if p.text[p.index] == ':'
                p.text[p.index + 1] != ':' && return EfusSyntaxError(
                    "Invalid type assert",
                    current_char(p, 1)
                )
                p.index += 2
                skip_spaces!(p)
                (type, token) = @zig! parse_jlexpressiontilltoken!(p, r",|\n")
                if token == "\n"
                    ended = true
                end
                type
            end
            if p.text[p.index] == ','
                p.index += 1
            end
        end
        code = skip_toblock!(p, [:end])
        isnothing(code) && return EfusSyntaxError("Missing closing end for snippet", b * e)
        (code,) = code
        content = @zig! subparse!(p, code, "In snippet starting at line $(b.start[1])")
        return Ast.Snippet(content, params)
    end
end
