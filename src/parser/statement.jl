function take_one!(p::EfusParser; expect_end::Bool = false)::Union{Ast.Statement, Nothing, Missing}
    ts = p.stream


    while true
        tk = peek(ts)
        isnothing(tk) && return nothing


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
        elseif tk.type === Tokens.COMMENT
            endstheline!(p, "After comment")
            continue
        end

        parent = isempty(p.stack) ? p.root : p.stack[end]

        statement = if tk.type === Tokens.IDENTIFIER
            nx = next!(ts)
            if nx.type === Tokens.JULIAEXPR
                name = Symbol(tk.token)
                params = try
                    Ast.takesnippetparameters(Meta.parse("$(nx.token) -> nothing").args[1])
                catch e
                    errmsg = e isa Meta.ParseError ? e.msg : string(e)
                    throw(ParseError("Error parsing arguments for snippet $name: $errmsg", nx.location))
                end
                next!(ts)
                endstheline!(p, "After snippet definition")

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
                    if next!(ts).type === Tokens.NEXTLINE
                        next!(ts)
                        endstheline!(p, "After nextline('|') in component call argument")
                    end
                    paramvalue = take_expression!(p)
                    isnothing(paramvalue) && throw(ParseError("Expected value", peek(ts).location))
                    push!(s.arguments, (paramname, paramsub, paramvalue))
                end
                endstheline!(p, "After component call")
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
            condition = take_juliaexpr!(p)
            isnothing(condition) && throw(
                ParseError(
                    "Expected condition, got $(loc.type)",
                    loc.location,
                )
            )
            endstheline!(p, "After if or elseif block condition")

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
            next!(ts)
            endstheline!(p, "After else")
            return take_one!(p)
        elseif tk.type === Tokens.FOR
            next!(ts)
            iterating = take_juliaexpr!(p)
            shouldbe(peek(ts), [Tokens.IN], "In for loop, expected in")
            next!(ts)
            iterator = take_juliaexpr!(p)
            endstheline!(p, "After for loop iterator")
            statement = Ast.For(; parent, iterating, iterator, block = Ast.Block())
            push!(p.stack, statement)
            p.last_statement = statement.block
            return statement
        elseif tk.type === Tokens.END
            if !isempty(p.stack)
                statement = p.stack[end]
                if statement isa Ast.If || statement isa Ast.For || statement isa Ast.Snippet
                    next!(ts)
                    endstheline!(p, "After end")
                    pop!(p.stack)
                    p.last_statement = nothing
                    continue
                end
            end
            if expect_end
                next!(ts)
                endstheline!(p, "After end")
                p.last_statement = nothing
                return missing
            else
                throw(ParseError("Unexpected end", tk.location))
            end

        elseif tk.type === Tokens.JULIAEXPR
            pos = tk.location.stop
            expr = take_juliaexpr!(p)
            if expr isa Ast.Reactor
                throw(
                    ParseError(
                        "Reactor not supported as julia blocks, use @reactor or @radical instead", tk.location,
                    )
                )
            end
            endstheline!(p, "After julia code block")
            Ast.JuliaBlock(; parent, code = expr)
        else
            throw(ParseError("Unexpected token $(tk.type) to start a statement", tk.location))
        end

        p.last_statement = statement
        return statement
    end
    return
end
