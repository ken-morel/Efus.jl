const BRACES = ("([{", ")]}")
const QUOTES = "'\""


function take_ionic!(tz::Tokenizer, endtokens::Vector{String} = String[])::Token
    bytetokens = codeunits.(endtokens)
    bytetokenlengths = length.(bytetokens)
    maxbytetokenlength = max(0, bytetokenlengths...)
    endtokenandsizes = zip(bytetokens, bytetokenlengths)
    ts = tz.stream
    startloc = location(ts)
    buffer = IOBuffer()

    brackets = Char[]

    stoploc = startloc.stop
    foundendtoken = false
    while !eof(ts)
        ch = peek(ts)
        if ch ∈ BRACES[1]
            push!(brackets, BRACES[2][findfirst(ch, BRACES[1])])
        elseif ch ∈ BRACES[2]
            stoplocation = Location(stoploc, stoploc, tz.stream.file)
            isempty(brackets) && return token(ERROR, "Unmatched closing '$ch', no brace was open :-(", stoplocation)
            brackets[end] !== ch && return token(ERROR, "Unexpected quote '$ch', expected '$(brackets[end])'", stoplocation)
            pop!(brackets)
            if isempty(brackets) && isempty(endtokens)
                write(buffer, ch)
                stoploc = loc(ts)
                next!(ts)
                break
            end
        elseif ch === '''
            prev = ts.prev
            if isnothing(prev) || !Meta.isidentifier("_" * prev)
                # We are surely at a character
                ch = take_char!(tz)
                ch.type === ERROR && return ch
                write(buffer, ch.token)
                continue
            else
                # We are at the end of a reactive variable
                # No story, just leave
            end
        elseif ch === '"'
            tk = take_string!(tz)
            tk.type === ERROR && return tk
            write(buffer, tk.token[begin:end])
            stoploc = loc(ts)
            continue
        end
        write(buffer, ch)
        stoploc = loc(ts)


        if !isempty(endtokens) && isempty(brackets)
            bflen = buffer.size
            for (endtoken, endtokensize) in endtokenandsizes
                endtokensize > bflen && continue
                if view(buffer.data, (bflen - endtokensize + 1):bflen) == endtoken
                    # Yeah, we got an endtoken
                    foundendtoken = true
                    break
                end
            end
            foundendtoken && break
        end

        next!(ts)
    end

    !isempty(brackets) && return token(
        ERROR,
        "Unclosed bracket started here",
        startloc,
    )

    return token(IONIC, String(take!(buffer)), startloc * stoploc)
end
