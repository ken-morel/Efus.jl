const ESCAPABLE = "\"\'ntrfa\\"

function take_string!(tz::Tokenizer)::Token
    ts = tz.stream
    buffer = IOBuffer("\"")
    @assert peek(ts) === '"' "Cannot take string if not at \""
    startloc = loc(ts)

    lastloc = loc(ts)
    while true
        eof(ts) && return token(
            ERROR,
            "Unterminated string at end of file",
            Location(lastloc, lastloc, ts.file),
        )
        ch = peek(ts)
        if ch === '\\'
            escaped = @next ch "In string escape"
            escaped ∉ ESCAPABLE && return token(
                ERROR,
                "Invlid escape: $escaped",
                location(ts)
            )
        elseif ch === '"'
            push!(buffer, ch)
            next!(ch)
            break
        end
        push!(buffer, ch)
        lastloc = loc(ts)
        next!(ts)
    end
    return token(STRING, String(take!(buffer)), Location(startloc, lastloc, ts.file))
end

function take_char!(tz::Tokenizer)::Token
    ts = tz.stream
    @assert peek(ts) == ''' "Character must start at '''"
    startloc = loc(ts)
    content = @next ts ""
    if content === '\\'
        escaped = @next ts "In character escape"
        content = "\\" * escaped
    end
    closing = @next ts "At closing character literal"
    endloc = loc(ts)
    return if closing === '''
        next!(ts)
        Token(CHAR, "'$content'", Location(startloc, endloc, ts.file))
    else
        Token(ERROR, "Expected closing ''' at end of character literal", location(ts))
    end
end
