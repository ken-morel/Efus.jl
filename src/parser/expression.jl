const DIRECT_EVAL = [Tokens.IDENTIFIER, Tokens.NUMERIC, Tokens.STRING, Tokens.CHAR, Tokens.SYMBOL]
function take_expression!(p::EfusParser)::Ast.Expression
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
    end
end
