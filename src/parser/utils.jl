function shouldbe(tk::Token, tkt::Vector{TokenType}, wh::String)
    return if tk.type ∉ tkt
        throw(ParseError("Unexpected token($(tk.type)) $wh", tk.location))
    else
        tk
    end
end
