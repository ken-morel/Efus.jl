const MARKEDREACTANT = r"(?<!')(\p{L}|_)(\p{L}|\p{N}|_)*'"

const INTERESTING_JLE = r"'|\"|\(|\)|\[|\]|(?<!')(\p{L}|_)(\p{L}|\p{N}|_)*'"
#                          |  |  |  |  |  |
#                          |  |  |  |  |  +-- reactive variables
#                          |  |  |  |  +-- square brackets
#                          |  |  |  +-- parentheses
#                          |  |  +-- strings
#                          |  +-- quotes
#                          +-- quotes

function parse_julia_expression!(p::EfusParser, stop_tokens::Union{Regex, Nothing} = nothing)::Union{Ast.Expression, AbstractParseError}
    return ereset(p) do
        start = p.index
        startpos = current_char(p)

        # Check for delimited expressions
        delimiters = nothing
        if inbounds(p)
            if p.text[p.index] == '('
                delimiters = ('(', ')')
                p.index += 1
            elseif p.text[p.index] == '['
                delimiters = ('[', ']')
                p.index += 1
            end
        end

        brackets = zero(UInt)
        reactants = Dict{Symbol, Vector{NTuple{2, UInt}}}()

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

            # Look for interesting tokens
            interesting = match(INTERESTING_JLE, p.text, p.index)

            # Look for stop tokens (only if not in delimited expression)
            stop_match = nothing
            if isnothing(delimiters) && !isnothing(stop_tokens)
                stop_match = match(stop_tokens, p.text, p.index)
            end

            # Look for closing delimiter
            close_match = nothing
            if !isnothing(delimiters) && brackets == 0
                close_match = match(Regex("\\$(delimiters[2])"), p.text, p.index)
            end

            # Determine which token to process
            if !isnothing(interesting) && (
                    (isnothing(stop_match) || interesting.offset < stop_match.offset) &&
                        (isnothing(close_match) || interesting.offset < close_match.offset) ||
                        brackets > 0
                )
                # Process interesting token
                if interesting.match == "(" || interesting.match == "["
                    brackets += 1
                    p.index = interesting.offset + 1
                elseif interesting.match == ")" || interesting.match == "]"
                    brackets -= 1
                    brackets < 0 && return EfusSyntaxError(
                        "Unmatched closing $(interesting.match) at position", current_char(p),
                    )
                    p.index = interesting.offset + 1
                elseif interesting.match == "\""
                    p.index = interesting.offset
                    @zig! parse_string!(p)
                elseif interesting.match == "'"
                    p.index = interesting.offset + 3
                else # a reactive expression
                    name = Symbol(interesting.match[begin:(end - 1)])
                    # Calculate position relative to the expression start
                    expr_start = isnothing(delimiters) ? start : start + 1
                    pos = (interesting.offset - expr_start + 1, interesting.offset - expr_start + length(interesting.match) - 1)
                    if name ∉ keys(reactants)
                        reactants[name] = []
                    end
                    push!(reactants[name], pos)
                    p.index = interesting.offset + length(interesting.match)
                end
            elseif !isnothing(close_match) && brackets == 0
                # Found closing delimiter
                p.index = close_match.offset + 1
                break
            elseif !isnothing(stop_match) && brackets == 0
                # Found stop token
                p.index = stop_match.offset + length(stop_match.match)
                break
            else
                # No interesting tokens found, advance
                p.index += 1
            end
        end

        # Extract the expression text
        expr_start = isnothing(delimiters) ? start : start + 1
        expr_end = if !isnothing(delimiters)
            p.index - 2  # p.index is after the closing delimiter, so -2 to exclude it
        else
            p.index - 1   # p.index is after the stop token
        end
        expr_text = p.text[expr_start:expr_end]

        return Ast.Expression(expr_text, reactants, delimiters)
    end
end

function parse_jlexpressiontilltoken!(p::EfusParser, token::Regex)::Union{Tuple{Ast.Expression, AbstractString}, AbstractParseError}
    return ereset(p) do
        start = p.index
        startpos = current_char(p)
        brackets = zero(UInt)
        instring = false
        reactants = Dict{Symbol, Vector{NTuple{2, UInt}}}()
        while true
            !inbounds(p) && return EfusSyntaxError(
                "OEF before end of julia expression started at pos",
                startpos,
            )
            interesting = match(INTERESTING_JLE, p.text, p.index)
            endtokenmatch = match(token, p.text, p.index)
            isnothing(endtokenmatch) && return EfusSyntaxError(
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
                # Calculate position relative to the start of the expression
                expr_start = start.start[2]  # Character position from the location
                pos = (1, p.index - expr_start + 1) .|> UInt
                p.index += 1
                # Check if we're at the end of the string or at whitespace
                if !inbounds(p) || isspace(p.text[p.index])
                    return Ast.Expression(string(name) * "'", Dict(name => [pos]), nothing)
                else
                    if inbounds(p)
                        return EfusSyntaxError("Unexpected token after reactive variable", current_char(p))
                    else
                        return EfusSyntaxError("Unexpected end of input after reactive variable", start)
                    end
                end
            else
                @zig! eoe(p, "In julia expression")

                !isnothing(name) && return Ast.Expression(string(name), Dict{Symbol, Vector{NTuple{2, UInt}}}(), nothing)
            end
        end
        if p.text[p.index] == ':'
            p.index += 1
            name = parse_symbol!(p)
            isnothing(name) && return EfusSyntaxError("Invalid julia Symbol at pos", start * current_char(p))
            return Ast.LiteralValue(name)
        elseif p.text[p.index] == '('
            return parse_julia_expression!(p, nothing)
        end
    end
end

function eoe(p::EfusParser, pos::AbstractString)
    return if inbounds(p) && !isspace(p.text[p.index])
        EfusSyntaxError("Unexpected token after end of expression $pos", current_char(p))
    end
end
