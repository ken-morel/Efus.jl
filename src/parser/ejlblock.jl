function parseejlblock!(parser::Parser)::Union{EJlBlock, AbstractEfusError}
    return resetiferror(parser) do
        indent = skipspaces!(parser)
        char(parser) == '(' || return nothing
        stack = ParserStack(
            parser.filename,
            LocatedArround(AFTER, line(parser), col(parser)),
            getline(parser),
            "in expression",
        )
        parser.index += 1
        start = parser.index
        count = 1
        while inbounds(parser)
            if char(parser) == '('
                count += 1
            elseif char(parser) == ')'
                count -= 1
            end
            count == 0 && break
            parser.index += 1
        end
        if count != 0
            return SyntaxError("Unterminated expression", stack)
        end
        stop = parser.index - 1
        parser.index += 1
        EJlBlock(indent, Meta.parse(parser.text[start:stop]; filename = "<ejlblock>"))
    end
end
