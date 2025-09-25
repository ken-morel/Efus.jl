const MARKEDREACTANT = r"(?<!')(\p{L}|_)(\p{L}|\p{N}|_)*'"

const INTERESTING_JLE = r"'|\"|\(|\)|(?<!')(\p{L}|_)(\p{L}|\p{N}|_)*'"
#                          |  |  |  |

function parse_jlexpressiontilltoken!(p::EfusParser, token::Regex)::Union{Tuple{Ast.Expression, AbstractString}, AbstractParseError}
    return ereset(p) do
        start = p.index
        startpos = current_char(p)
        brackets = zero(UInt)
        instring = false
        reactants = Dict{Symbol, Vector{NTuple{2, UInt}}}()
        while true
            !inbounds(p) && return AbstractParseError(
                "OEF before end of julia expression started at pos",
                startpos,
            )
            interesting = match(INTERESTING_JLE, p.text, p.index)
            endtokenmatch = match(token, p.text, p.index)
            isnothing(endtokenmatch) && return AbstractParseError(
                "Ending token $token not found while parsing expression",
                startpos,
            )
            if !isnothing(interesting) && (interesting.offset < endtokenmatch.offset || brackets > 0)
                if interesting.match == "("
                    brackets += 1
                    p.index = interesting.offset + 1
                elseif interesting.match == ")"
                    brackets -= 1
                    brackets < 0 && return EfusSyntaxError(
                        "Unmatched closing brace at position", current_char(p),
                    )
                    p.index = interesting.offset + 1
                elseif interesting.match == "\""
                    p.index = interesting.offset
                    @zig! parse_string!(p)
                elseif interesting.match == "'"
                    p.index = interesting.offset + 3
                else # a reactive expression
                    name = Symbol(interesting.match[begin:(end - 1)])
                    # My first ever dot macro usage :-)
                    pos = (0, length(interesting.match) - 1)
                    pos = @. interesting.offset + pos - start + 1
                    if name ∉ keys(reactants)
                        reactants[name] = []
                    end
                    push!(reactants[name], pos)
                    p.index = interesting.offset + length(interesting.match)
                end
            else
                brackets != 0 && return EfusSyntaxError("Unmatched brackets in expression started at pos", startpos)
                p.index = endtokenmatch.offset + length(endtokenmatch.match)
                return (
                    Ast.Expression(
                        p.text[start:(endtokenmatch.offset - 1)],
                        reactants
                    ), endtokenmatch.match,
                )
            end
        end
    end
end

function parse_juliaexpression!(p::EfusParser)::Union{Ast.Expression, Ast.LiteralValue, AbstractParseError, Nothing}
    return ereset(p) do
        start = current_char(p)
        name = parse_symbol!(p)
        if !isnothing(name)
            if inbounds(p) && p.text[p.index] == '''
                pos = (1, p.index) .|> UInt
                p.index += 1
                @zig! eoe(p)
                return Ast.Expression(string(name) * "'", Dict(name => [pos]))
            else
                @zig! eoe(p)

                !isnothing(name) && return Ast.Expression(string(name), Dict())
            end
        end
        if p.text[p.index] == ':'
            p.index += 1
            name = parse_symbol!(p)
            isnothing(name) && return EfusSyntaxError("Invalid julia Symbol at pos", start * current_char(p))
            return Ast.LiteralValue(name)
        elseif p.text[p.index] == '('
            p.index += 1
            !inbounds(p) && return EfusSyntaxError("EOF Before literal expression at ", current_char(p, -1))
            (expr,) = @zig! parse_jlexpressiontilltoken!(p, r"\)")
            return expr
        end
    end
end

function eoe(p::EfusParser)
    return if inbounds(p) && !isspace(p.text[p.index])
        EfusSyntaxError("Unexpected token after end of expression", current_char(p))
    end
end
