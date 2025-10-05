function take_one!(p::EfusParser)::Union{Ast.Statement, Nothing}
    ts = p.stream


    while true
        tk = peek(ts)

        if tk.type === Tokens.EOL
            next!(ts)
            continue
        elseif tk.type === Tokens.INDENT
            if isnothing(p.last_statement)
                throw(ParseError("Unexpected indent", tk.location))
            end
            push!(p.stack, p.last_statement)
            p.last_statement = nothing
            next!(ts)
            continue
        elseif tk.type === Tokens.DEDENT
            if isempty(p.stack)
                throw(ParseError("Unbalanced dedent", tk.location))
            end
            pop!(p.stack)
            p.last_statement = nothing
            next!(ts)
            continue
        elseif tk.type === Tokens.EOF
            if !isempty(p.stack)
                throw(ParseError("Unexpected EOF, unclosed blocks.", tk.location))
            end
            return nothing
        end

        parent = isempty(p.stack) ? nothing : p.stack[end]

        statement = if tk.type === Tokens.IDENTIFIER
            s = Ast.ComponentCall(; parent, componentname = Symbol(tk.token))
            next!(ts)
            while !isending(peek(ts))
                arg_tk = peek(ts)
                shouldbe(arg_tk, [Tokens.IDENTIFIER], "In component call, expected argument name")
                paramname = Symbol(arg_tk.token)
                nx = next!(ts)

                if nx.type === Tokens.SPLAT
                    push!(s.splats, paramname)
                    next!(ts)
                    continue
                end

                paramsub = if nx.type === Tokens.SYMBOL
                    n = nx.token
                    nx = next!(ts)
                    Symbol(n[2:end])
                end

                shouldbe(nx, [Tokens.EQUAL], "After component call argument name, expected equal, got '$(nx.token)'")
                next!(ts)
                paramvalue = take_expression!(p)
                isnothing(paramvalue) && throw(ParseError("Expected value", peek(ts).location))
                push!(s.arguments, (paramname, paramsub, paramvalue))
            end
            s
        elseif tk.type === Tokens.IF || tk.type === Tokens.ELSEIF
            isif = tk.type === Tokens.IF
            statement = if isif
                s = Ast.If(; parent)
                push!(p.stack, s)
                s
            else
                if isempty(p.stack) || !isa(p.stack[end], Ast.If)
                    throw(ParseError("Unexpected elseif", tk.location))
                else
                    p.stack[end]
                end
            end
            loc = next!(ts)
            condition = take_expression!(p)
            isnothing(condition) && throw(
                ParseError(
                    "Expected condition, got $(loc.type)",
                    loc.location,
                )
            )
            !isending(peek(ts)) && throw(
                ParseError(
                    "Expected EOL after condition, got $(peek(ts))",
                    peek(ts).location,
                )
            )
            next!(ts)
            branch = Ast.IfBranch(; condition)
            push!(statement.branches, branch)
            p.last_statement = branch
            if isif
                return statement
            else
                return take_one!(p)
            end
        elseif tk.type === Tokens.ELSE
            statement = if isempty(p.stack) || !isa(p.stack[end], Ast.If)
                throw(ParseError("Unexpected else", tk.location))
            else
                p.stack[end]
            end
            branch = Ast.IfBranch(; condition = nothing)
            push!(statement.branches, branch)
            p.last_statement = branch
            isending(next!(p.stream)) || throw(ParseError("Expected EOL after else, got $(peek(p.stream))", peek(p.stream).location))
            next!(p.stream)
            return take_one!(p)
        elseif tk.type === Tokens.END
            if !isempty(p.stack)
                statement = p.stack[end]
                if statement isa Ast.If
                    eof = next!(ts)
                    isending(eof) || throw(
                        ParseError(
                            "Unexpected token after END: $eof", eof.location
                        )
                    )
                    pop!(p.stack)
                    next!(ts)
                    p.last_statement = nothing
                    continue
                end
            end
            throw(ParseError("Unexpected end", tk.location))
        else
            throw(ParseError("Unexpected token $(tk.type) to start a statement", tk.location))
        end

        p.last_statement = statement
        return statement
    end
    return
end
