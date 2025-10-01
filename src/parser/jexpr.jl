const MARKEDREACTANT = r"(?<!')(\p{L}|_)(\p{L}|\p{N}|_)*'"

const INTERESTING_JLE = r"'|\"|\(|\)|\[|\]|\{|\}|(?<!')(\p{L}|_)(\p{L}|\p{N}|_)*'|(-|\+)?([\d_]+)(\.[\d_]*)?([eE](?:\+|-)?\d+)?'"

const BRACES = Dict('[' => ']', '(' => ')', '{' => '}')
#                                                                                | number


function skip_julia!(p::EfusParser, stop_tokens::Union{Regex, Nothing} = nothing)::Union{String, Nothing, AbstractParseError}
    return ereset(p) do
        start = p.index
        startpos = current_char(p)

        delimiters = nothing
        if inbounds(p)
            if p.text[p.index] == '('
                delimiters = ('(', ')')
                p.index += 1
            elseif p.text[p.index] == '['
                delimiters = ('[', ']')
                p.index += 1
            elseif p.text[p.index] == '{'
                delimiters = ('{', '}')
                p.index += 1
            end
        end
        brackets = Char[]

        stop = start
        while true
            !inbounds(p) && begin
                if !isnothing(delimiters)
                    return EfusSyntaxError(
                        "EOF before closing $(delimiters[2]) for expression started at pos",
                        startpos,
                    )
                elseif !isnothing(stop_tokens)
                    return EfusSyntaxError(
                        "EOF before stop token $stop_tokens for expression started at pos",
                        startpos,
                    )
                else
                    break
                end
            end

            interesting = match(INTERESTING_JLE, p.text, p.index)

            stop_match = nothing
            if isnothing(delimiters) && !isnothing(stop_tokens)
                stop_match = match(stop_tokens, p.text, p.index)
            end

            close_match = nothing
            if !isnothing(delimiters) && isempty(brackets)
                close_match = match(Regex("\\$(delimiters[2])"), p.text, p.index)
            end

            if !isnothing(interesting) && (
                    (isnothing(stop_match) || interesting.offset < stop_match.offset) &&
                        (isnothing(close_match) || interesting.offset < close_match.offset) ||
                        !isempty(brackets)
                )
                if interesting.match[1] in keys(BRACES)
                    push!(brackets, BRACES[interesting.match[1]])
                    p.index = interesting.offset + 1
                elseif interesting.match[1] in values(BRACES)
                    isempty(brackets) && return EfusSyntaxError(
                        "Unmatched closing $(interesting.match) at position", current_char(p),
                    )
                    last = pop!(brackets)
                    interesting.match[1] != last && return EfusSyntaxError(
                        "Unexpected closing bracket $(interesting.match) at position, expected $(last)", current_char(p),
                    )
                    p.index = interesting.offset + 1
                elseif interesting.match == "\""
                    p.index = interesting.offset
                    @zig! parse_string!(p)
                elseif interesting.match == "'"
                    p.index = interesting.offset + 3
                else
                    p.index = interesting.offset + length(interesting.match)
                end
            elseif !isnothing(close_match) && isempty(brackets)
                p.index = close_match.offset + 1
                stop = close_match.offset
                break
            elseif !isnothing(stop_match) && isempty(brackets)
                p.index = stop_match.offset + length(stop_match.match)
                stop = stop_match.offset - 1
                break
            else
                p.index += 1
            end
        end
        return p.text[start:stop]
    end
end

function parse_juliaexpression!(p::EfusParser, stop_tokens::Union{Regex, Nothing} = nothing)::Union{Ast.Expression, AbstractParseError, Nothing}
    return ereset(p) do
        start = current_char(p)
        expr = @zig! skip_julia!(p, stop_tokens)
        isnothing(expr) && return nothing
        try
            Ast.Expression(Meta.parse(expr))
        catch e
            EfusSyntaxError("Invalid Julia expression: $(e.msg)", start * current_char(p, -1))
        end
    end
end
