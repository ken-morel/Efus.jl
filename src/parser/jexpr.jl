const EXPRQUOTE = r"\"|'"
const BRACKETQUOTE = r"\(|\)"
function parse_juliaexpression!(p::EfusParser)::Union{Ast.Expression, AbstractParseError, Nothing}
    return ereset(p) do
        start = current_char(p)
        name = parse_symbol!(p)
        !isnothing(name) && return Ast.Expression(string(name))
        if p.text[p.index] == '$'
            p.index += 1
            name = parse_symbol!(p)
            isnothing(name) && return EfusSyntaxError("Expected reactant name after '\$' in reactive expression", current_char(p, -1))
            return Ast.Expression("\$" * string(name))
        elseif p.text[p.index] == '('
            count = 1
            p.index += 1
            !inbounds(p) && return EfusSyntaxError("EOF Before literal expression at ", current_char(p, -1))
            exprstart = p.index
            while true
                nextquote = if inbounds(p)
                    match(EXPRQUOTE, p.text, p.index)
                end
                next = if inbounds(p)
                    match(BRACKETQUOTE, p.text, p.index)
                end
                isnothing(next) && return EfusSyntaxError("Unterminated literal expression started here", start)
                if !isnothing(nextquote) && nextquote.offset < next.offset
                    p.index = nextquote.offset
                    val = nothing
                    @zig! val parse_string!(p)
                    isnothing(val) && AssertionError("Must me a string here")
                    continue
                end
                count += next.match == "(" ? 1 : -1
                p.index = next.offset + length(next.match)
                count == 0 && break
            end
            return Ast.Expression(p.text[exprstart:(p.index - 2)])
        end
    end
end
