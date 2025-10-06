const DIRECT_EVAL = [Tokens.IDENTIFIER, Tokens.NUMERIC, Tokens.STRING, Tokens.CHAR, Tokens.SYMBOL]
function take_expression!(p::EfusParser; mustbe::Bool = true)::Union{Ast.Expression, Nothing}
    tk = peek(p.stream)
    ts = p.stream
    return if tk.type === Tokens.IONIC
        nx = next!(ts)
        expr = Meta.parse(tk.token)
        type = if nx.type === Tokens.TYPEASSERT
            next!(ts)
            Meta.parse(nx.token)
        end
        Ast.Ionic(expr, type)
    elseif tk.type ∈ DIRECT_EVAL
        next!(ts)
        expr = Meta.parse(tk.token)
        Ast.Julia(expr)
    elseif tk.type === Tokens.SQOPEN
        next!(ts)
        contents = Ast.Expression[]
        while true
            while peek(ts).type ∈ (Tokens.EOL, Tokens.INDENT, Tokens.DEDENT)
                next!(ts)
            end
            if peek(ts).type === Tokens.SQCLOSE
                next!(ts)
                break
            end
            push!(contents, take_expression!(p; mustbe = true))

            while peek(ts).type ∈ (Tokens.EOL, Tokens.INDENT, Tokens.DEDENT)
                next!(ts)
            end

            tk_after = peek(ts)
            if tk_after.type === Tokens.SQCLOSE
                continue
            elseif tk_after.type === Tokens.COMMA
                next!(ts)
            else
                throw(ParseError("Expected comma or ']' in vector, got $(tk_after.type)", tk_after.location))
            end
        end
        Ast.Vect(contents)
    elseif mustbe
        throw(ParseError("Expected expression, got $tk", tk.location))
    end
end
