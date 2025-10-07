function shouldbe(tk::Token, tkt::Vector{TokenType}, wh::String)
    return if tk.type ∉ tkt
        throw(ParseError("Unexpected token($(tk.type)) $wh", tk.location))
    else
        tk
    end
end

function endstheline!(p::EfusParser, wh::String)
    tk = peek(p.stream)
    shouldbe(tk, [Tokens.EOL, Tokens.EOL], "Expected eol $wh got $(tk)")
    next!(p.stream)
    return
end
