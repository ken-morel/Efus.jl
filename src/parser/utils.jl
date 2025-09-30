const SPACE = r"^ *"
const SPACENEWLINE = r"^[ \n]*"

function skip_spaces!(p::EfusParser; newline::Bool = false)::UInt
    m = match(newline ? SPACENEWLINE : SPACE, p.text[p.index:end])
    p.index += length(m.match)
    return length(m.match)
end

function ereset(f::Function, p::EfusParser)
    idx = p.index
    return try
        r = f()
        if r isa AbstractParseError || isnothing(r)
            p.index = idx
        end
        r
    catch e
        if e isa BoundsError
            p.index = length(p.text)
            pos = (line(p), col(p))
            p.index = idx
            EfusSyntaxError("Unexpected EOF at position.", Ast.Location(p.file, pos, pos))
        else
            rethrow()
        end
    end
end

inbounds(p::EfusParser) = length(p.text) >= p.index

function skip_emptylines!(p::EfusParser)
    while inbounds(p)
        line_start = p.index
        line_end = findnext(==('\n'), p.text, line_start)

        if isnothing(line_end)
            if all(isspace, p.text[line_start:end])
                p.index = length(p.text) + 1
            end
            break
        else
            if all(isspace, p.text[line_start:line_end])
                p.index = line_end + 1
            else
                break
            end
        end
    end
    return inbounds(p)
end
function skip_toblock!(p::EfusParser, names::Vector{Symbol})::Union{Tuple{String, Symbol, Ast.Location}, Nothing}
    return ereset(p) do
        start = p.index
        stop = p.index
        scope = zero(UInt)
        while inbounds(p)
            skip_spaces!(p)
            b = current_char(p)
            name = parse_symbol!(p)
            e = current_char(p, -1)
            if name == :end && inbounds(p)
                if p.text[p.index] == ')' #BUG: Completely bug prone
                    name = nothing
                end

            end
            if name ∈ names && scope == 0
                return (p.text[start:stop], name, b * e)
            elseif name ∈ OPENING_CONTROLS
                scope += 1
            elseif name == :end
                scope -= 1
            end
            if scope < 0
                return EfusSyntaxError("Unmatched end", b * e)
            end
            if inbounds(p)
                newline = findnext('\n', p.text, p.index)
                if !isnothing(newline)
                    p.index = newline + 1
                    stop = p.index
                    continue
                end
            end
            return nothing
        end
    end
end


const SYMBOL = r"(\p{L}|_)(\p{L}|\p{N}|_)*"
function parse_symbol!(p::EfusParser)::Union{Symbol, Nothing}
    inbounds(p) || return nothing
    m = match(SYMBOL, p.text, p.index)
    return if !isnothing(m) && m.offset == p.index
        p.index += length(m.match)
        Symbol(m.match)
    end
end
