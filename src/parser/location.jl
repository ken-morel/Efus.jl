function current_char(p::EfusParser, offset::Number = 0)::Ast.Location
    p.index += offset
    pos = (line(p), col(p))
    p.index -= offset
    return Ast.Location(
        p.file,
        pos,
        pos
    )

end

function line(p::EfusParser)
    end_idx = min(p.index, length(p.text))
    return count(==('\n'), p.text[begin:end_idx]) + 1
end

function col(p::EfusParser)
    end_idx = min(p.index, length(p.text))
    last_newline = findlast('\n', p.text[begin:end_idx])
    return p.index - something(last_newline, 0)
end
