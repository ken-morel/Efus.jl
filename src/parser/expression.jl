const DIRECT_EVAL =
    [Tokens.IDENTIFIER, Tokens.NUMERIC, Tokens.STRING, Tokens.CHAR, Tokens.SYMBOL]
function take_juliaexpr!(p::EfusParser)::Union{Ast.Reactor,Ast.Julia,Ast.Arrow}
    ts = p.stream
    tk = peek(ts)
    exprtoken = tk
    expr = try
        Meta.parse(tk.token)
    catch e
        message = e isa Meta.ParseError ? e.msg : string(e)
        throw(ParseError("Error parsing expression: $message", tk.location))
    end
    nx = next!(ts)

    typetoken = nothing
    type = if nx.type === Tokens.TYPEASSERT
        typetoken = nx
        next!(ts)
        try
            Meta.parse(nx.token)
        catch e
            message = e isa Meta.ParseError ? e.msg : string(e)
            throw(ParseError("Error parsing expression: $message", nx.location))
        end
    end
    params =
        isnothing(type) ? Ast.Julia(; expr, token = exprtoken) :
        Ast.Reactor(; expr, type, tokens = (; expr = exprtoken, type = typetoken))
    return if peek(ts).type == Tokens.ARROW # An arrow
        arrowtoken = peek(ts)
        next!(ts)
        content = take_expression!(p; mustbe = true)
        Ast.Arrow(params, content, token = arrowtoken)
    else
        params
    end
end
function take_expression!(p::EfusParser; mustbe::Bool = true)::Union{Ast.Expression,Nothing}
    tk = peek(p.stream)
    ts = p.stream
    return if tk.type === Tokens.JULIAEXPR
        take_juliaexpr!(p)
    elseif tk.type ∈ DIRECT_EVAL
        next!(ts)
        expr = Meta.parse(tk.token)
        Ast.Julia(; expr, token = tk)
    elseif tk.type === Tokens.SQOPEN
        take_vect!(p)
    elseif mustbe
        throw(ParseError("Expected expression, got $tk", tk.location))
    end
end

function take_vect!(p::EfusParser)
    stoptoken = Ref{Tokens.Token}()
    ts = p.stream
    starttoken = peek(ts)
    next!(ts)
    contents = Ast.Expression[]
    while true
        while peek(ts).type ∈ (Tokens.EOL, Tokens.INDENT, Tokens.DEDENT)
            next!(ts)
        end
        if peek(ts).type === Tokens.SQCLOSE
            stoptoken[] = peek(ts)
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
            throw(
                ParseError(
                    "Expected comma or ']' in vector, got $(tk_after.type)",
                    tk_after.location,
                ),
            )
        end
    end
    return Ast.Vect(; items = contents, tokens = (; start = starttoken, stop = stoptoken[]))
end
