function parseinlinecomment!(parser::Parser)::Union{String, Nothing}
    char(parser) == '#' || return nothing
    start = parser.index
    return if '\n' ∈ aftercursor(parser)
        parser.index += findfirst(==('\n'), aftercursor(parser))
        parser.text[(start + 1):(parser.index - 1)]
    else
        parser.index = length(parser.text)
        parser.text[(start + 1):end]
    end
end

function parsecomment!(parser::Parser)::Union{EComment, Nothing}
    start = parser.index
    indent = skipspaces!(parser)
    cline = line(parser)
    fcol = col(parser)
    comment = parseinlinecomment!(parser)
    ecol = col(parser, parser.index - 1)
    if isnothing(comment)
        parser.index = start
        return nothing
    end
    return EComment(
        comment,
        ParserStack(
            parser.filename,
            LocatedBetween(cline, fcol, ecol),
            getline(parser),
            "comment statement",
        )
    )
end
