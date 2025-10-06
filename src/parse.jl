function parse_efus(code::AbstractString, file::AbstractString = "<string>")::Ast.Block
    io = IOBuffer(code)
    tokenstream = Channel{Tokens.Token}()
    aststream = Channel{Ast.Statement}()

    tokenizer = Tokens.Tokenizer(tokenstream, Tokens.TextStream(io, file))
    parser = Parser.EfusParser(Parser.TokenStream(tokenstream), aststream)


    toplevels = Ast.Statement[]

    errormonitor(@async Tokens.tokenize!(tokenizer))
    errormonitor(
        @async while true
            try
                statement = take!(aststream)
                if isnothing(statement.parent)
                    push!(toplevels, statement)
                else
                    Ast.affiliate!(statement)
                end
            catch e
                if e isa InvalidStateException
                    break
                else
                    rethrow()
                end
            end
        end
    )

    try
        Parser.parse!(parser)
    catch err
        if err isa Parser.ParseError && err.location.file === file
            lineindex = err.location.start.ln
            lines = split(code, '\n')
            if lineindex <= length(lines)
                err.line = lines[lineindex]
            end
        end
        rethrow(err)
    end

    return Ast.Block(toplevels)
end
