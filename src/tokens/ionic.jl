const BRACES = ("([{", ")]}")
const QUOTES = "'\""


function take_ionic!(tz::Tokenizer, endtokens::Vector{String} = [])::Token
    bytetokens = codeunits.(endtokens)
    bytetokenlengths = length.(bytetokens)
    maxbytetokenlength = max(bytetokenlengths...)
    endtokensizes = zip(bytetokens, bytetokenlengths)
    ts = tz.stream
    startloc = loc(ts)
    buffer = IOBuffer()

    delimiters = nothing
    ch = peek(ts)
    push!(buffer, ch)
    if ch == '('
        delimiters = ('(', ')')
        next!(ts)
    elseif ch == '['
        delimiters = ('[', ']')
        next!(ts)
    elseif ch == '{'
        delimiters = ('{', '}')
        next!(ts)
    else
        pop!(buffer)
    end
    brackets = Char[]

    stoploc = startloc
    foundendtoken = false
    while !eof(ts)
        ch = peek(ts)
        if ch ∈ BRACES[1]
            push!(brackets, ch)
        elseif ch ∈ BRACES[2]
            isempty(brackets) && return token(ERROR, "Unmatched closing '$ch'", stoploc)
            brackets[end] !== ch && return token(ERROR, "Unexpected quote '$ch', expected '$(brackets[end])'", stoploc)
            pop!(brackets)
            if isempty(brackets) && isempty(endtokens)
                next!(ts)
                break
            end
        elseif ch === '''
            prev = ts.prev
            if isnothing(prev) || !Meta.isidentifier("_" * prev)
                # We are surely at a character
                ch = take_char!(tz)
                ch.type === ERROR && return ch
                push!(buffer, ch.token)
                continue
            else
                # We are at the end of a reactive variable
                # No story, just leave
            end
        elseif ch === '"'
            tk = take_string!(tz)
            tk.type === ERROR && return tk
        end
        push!(buffer, ch)
        stoploc = loc(ts)
        next!(ts)


        if !isempty(endtokens) && isempty(brackets)
            bflen = length(buffer.data)
            for (endtoken, endtokensize) in endtokensizes
                endtokensize > bflen && continue
                if view(buffer.data, (bflen - endtokensize):bflen) == endtoken
                    # Yeah, we got an endtoken
                    foundendtoken = true
                    break
                end
            end
            foundendtoken && break
        end
    end
    !isempty(brackets) && return token(
        ERROR,
        "Unclosed bracket started here",
        startloc,
    )

    return Token(IONIC, String(take!(buffer)), Location(startloc, stoploc, ts.file))
end
