function parse_efus(code::AbstractString, file::AbstractString = "<string>")::Ast.Block
    io = IOBuffer(code)
    tokenizer = Tokens.Tokenizer(Tokens.TextStream(io, file))
    parser = Parser.EfusParser(tokenizer)


    errormonitor(@async Tokens.tokenize!(tokenizer))
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

    return parser.root
end
