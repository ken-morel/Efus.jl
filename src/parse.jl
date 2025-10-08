export parse_efus

"""
    parse_efus(code::AbstractString, file::AbstractString = "<string>")::Ast.Block

This function wraps arround efus parser and tokenizer to provide
a moderately good error reporting and easyness of use.

See also [`Tokens.Tokenizer`](@ref), [`Parser.EfusParser`](@ref), 
[`Parser.ParseError`](@ref).
"""
function parse_efus(code::AbstractString, file::AbstractString = "<string>")::Ast.Block
    io = IOBuffer(code)
    tokenizer = Tokens.Tokenizer(Tokens.TextStream(io, file))

    tokens = Tokens.tokenize!(tokenizer)

    parser = Parser.EfusParser(tokens)
    try
        Parser.parse!(parser)
    catch err
        if err isa Parser.ParseError && err.location.file == file
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
