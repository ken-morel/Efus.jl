function take_one!(p::EfusParser; expect_end::Bool = false)::Union{Ast.Statement, Nothing, Missing}
    ts = p.stream


    while true
        tk = peek(ts)

        if tk.type === Tokens.EOL
            next!(ts)
            continue
        elseif tk.type === Tokens.INDENT
            if isnothing(p.last_statement)
                throw(ParseError("Unexpected indent, no preceding parent or sibling component", tk.location))
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
            nx = next!(ts)
            if nx.type === Tokens.IONIC
                name = Symbol(tk.token)
                params = try
                    Meta.parse("($(nx.token)) -> nothing").args[1]
                catch e
                    throw(ParseError("Error parsing arguments for snippet $name: $e", nx.location))
                end
                shouldbe(next!(ts), [Tokens.EOL], "Expected EOL after snippet definition")

                snippet = Ast.Snippet(; parent, name, params)

                push!(p.stack, snippet)
                p.last_statement = snippet.block
                return snippet
            else
                s = Ast.ComponentCall(; parent, componentname = Symbol(tk.token))
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

                    shouldbe(nx, [Tokens.EQUAL], "After component call argument name, expected equal after $arg_tk, got '$(nx)'")
                    next!(ts)
                    paramvalue = take_expression!(p)
                    isnothing(paramvalue) && throw(ParseError("Expected value", peek(ts).location))
                    push!(s.arguments, (paramname, paramsub, paramvalue))
                end
                s
            end

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
            statement = if isempty(p.stack)
                throw(ParseError("Unexpected else", tk.location))
            else
                p.stack[end]
            end
            p.last_statement = if statement isa Ast.If
                branch = Ast.IfBranch(; condition = nothing)
                push!(statement.branches, branch)
                branch
            elseif statement isa Ast.For
                statement.elseblock = Ast.Block()
            else
                throw(ParseError("Unexpected else", tk.location))
            end
            isending(next!(p.stream)) || throw(ParseError("Expected EOL after else, got $(peek(p.stream))", peek(p.stream).location))
            next!(p.stream)
            return take_one!(p)
        elseif tk.type === Tokens.FOR
            next!(ts)
            iterating = take_expression!(p)
            shouldbe(peek(ts), [Tokens.IN], "In for loop, expected in")
            next!(ts)
            iterator = take_expression!(p)
            isending(peek(ts)) || throw(
                ParseError(
                    "Expected EOL after for loop",
                    peek(ts).location
                )
            )
            statement = Ast.For(; parent, iterating, iterator, block = Ast.Block())
            push!(p.stack, statement)
            p.last_statement = statement.block
            return statement
        elseif tk.type === Tokens.END
            if !isempty(p.stack)
                statement = p.stack[end]
                if statement isa Ast.If || statement isa Ast.For || statement isa Ast.Snippet
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
            if expect_end
                eof = next!(ts)
                isending(eof) || throw(
                    ParseError(
                        "Unexpected token after END: $eof", eof.location
                    )
                )
                next!(ts)
                p.last_statement = nothing
                return missing
            else
                throw(ParseError("Unexpected end", tk.location))
            end

        else
            throw(ParseError("Unexpected token $(tk.type) to start a statement", tk.location))
        end

        p.last_statement = statement
        return statement
    end
    return
end
