function parse_snippet!(p::EfusParser)::Union{Ast.Snippet, AbstractParseError, Nothing}
    return ereset(p) do
        b = current_char(p)
        parse_symbol!(p) != :do && return nothing
        e = current_char(p, -1)
        # collect arguments, name::Type, puh, julia.
        params = Dict{Symbol, Any}()
        ended = false
        while !ended
            skip_spaces!(p)
            name = parse_symbol!(p)
            isnothing(name) && break
            skip_spaces!(p)
            params[name] = if p.text[p.index] == ':'
                p.text[p.index + 1] != ':' && return EfusSyntaxError(
                    "Invalid type assert",
                    current_char(p, 1)
                )
                p.index += 2
                skip_spaces!(p)
                type = @zig! parse_juliaexpression!(p, r",|\n")
                p.index -= 1
                # Check if we hit a newline (end of parameters)
                if p.text[p.index] == '\n'
                    ended = true
                end
                type
            end
            if p.text[p.index] == ','
                p.index += 1
            end
        end
        codestart = p.index
        code = skip_toblock!(p, [:end])
        isnothing(code) && return EfusSyntaxError("Missing closing end for snippet", b * e)
        (code,) = code
        content = @zig! subparse!(p, code, "In snippet starting at line $(b.start[1])", codestart)
        return Ast.Snippet(content, params)
    end
end

function parse_block!(p::EfusParser)::Union{Ast.InlineBlock, AbstractParseError, Nothing}
    return ereset(p) do
        b = current_char(p)
        parse_symbol!(p) != :begin && return nothing
        e = current_char(p, -1)
        codestart = p.index
        code = skip_toblock!(p, [:end])
        isnothing(code) && return EfusSyntaxError("Missing closing end for block", b * e)
        (code,) = code
        return Ast.InlineBlock(subparse!(p, code, "In begin block starting at line $(b.start[1])", codestart))
    end
end

function parse_juliablock!(p::EfusParser)::Union{Ast.JuliaBlock, AbstractParseError, Nothing}
    return ereset(p) do
        p.text[p.index] != '(' && return nothing
        expr = @zig! parse_juliaexpression!(p, nothing)
        Ast.JuliaBlock(; code = expr)
    end
end
