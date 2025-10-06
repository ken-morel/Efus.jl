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
        contents = Ast.Expression[]
        next!(ts)
        while true
            tk = peek(ts)
            if tk.type ∈ (Tokens.COMMA, Tokens.EOL, Tokens.INDENT, Tokens.DEDENT)
                next!(ts)
                continue
            elseif tk.type === Tokens.SQCLOSE
                break
            end
            push!(contents, take_expression!(p; mustbe = true))
        end
        next!(ts)
        Ast.Vect(contents)
    elseif mustbe
        throw(ParseError("Expected expression, got $tk", tk.location))
    end
end
