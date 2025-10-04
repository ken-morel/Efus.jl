export Tokenizer

"""
    Base.@kwdef struct Tokenizer

The efus code tokenizer.
Reads characters from a [`TextStream`](@ref), which can 
wrap channels, IO, or strings and outputs 
by calling an output function.
"""
struct Tokenizer
    out::Union{Function, Nothing}
    stream::TextStream
    pending::Vector{Token}
    indents::Vector{UInt}
    """
    Tokenizer(out::Union{Function, Nothing}, stream::TextStream)

    # Arguments
    - `out::Function`: The output function which will be called with every new 
      [`Token`](@ref).
    - `stream::TextStream`: The [`TextStream`](@ref) for the tokenizer to read from.

    See also [`tokenize!`](@ref).
    """
    Tokenizer(out::Union{Function, Nothing}, stream::TextStream) = new(out, stream, [], [0x00])
    Tokenizer(stream::TextStream) = Tokenizer(nothing, stream)
end

Tokenizer(
    out::Channel{Token}, stream::TextStream,
) = Tokenizer(stream) do token
    put!(out, token)
end
function Base.take!(tz::Tokenizer; put = true)::Token
    tk = _take!(tz)
    put && !isnothing(tz.out) && tz.out(tk)
    return tk
end

function _take!(tz::Tokenizer)::Token
    if !isempty(tz.pending)
        return popfirst!(tz.pending)
    end

    if bol(tz.stream)
        current_indent = length(take_while!(tz.stream, isindent)[1])

        last_indent = tz.indents[end]

        if current_indent > last_indent
            push!(tz.indents, current_indent)
            return token(INDENT, "", location(tz.stream))
        elseif current_indent < last_indent
            while current_indent < tz.indents[end]
                pop!(tz.indents)
                # An indent was skept e.g 0 -> 4 -> 2
                if current_indent > tz.indents[end]
                    return token(ERROR, "Invalid deindent, expected $(tz.indents[end]), got $current_indent", location(tz.stream))
                end
                push!(tz.pending, token(DEDENT, "", location(tz.stream)))
            end
            return popfirst!(tz.pending)
        end
    end
    ch = peek(tz.stream)
    return if eof(tz.stream)
        while length(tz.indents) > 1
            pop!(tz.indents)
            push!(tz.pending, token(DEDENT, "", location(tz.stream)))
        end
        !isempty(tz.pending) && return popfirst!(tz.pending)
        token(EOF, "", location(tz.stream))
    elseif eol(tz.stream)
        pos = location(tz.stream)
        next!(tz.stream)
        token(EOL, "", pos)
    elseif isindent(ch)
        skip_while!(tz.stream, isindent)
        take!(tz)
    elseif Meta.isidentifier(string(ch))
        identifier = take_identifier!(tz)
        identifier.type === ERROR && return identifier
        if identifier.token ∈ keys(KEYWORDS)
            tk = token(KEYWORDS[identifier.token], "", identifier.location)
            if tk.type == IN || tk.type == IF # take in iterating
                skip_while!(tz.stream, isindent)
                cond = take_ionic!(tz, ["\n"])
                println(peek(tz.stream))
                cond.type == ERROR && return cond
                push!(tz.pending, token(IONIC, cond.token[begin:(end - 1)], cond.location))
                tk
            else
                tk
            end
        elseif peek(tz.stream) == '''
            pos = loc(tz.stream)
            next!(tz.stream)
            token(IONIC, identifier.token * ''', identifier.location * pos)
        else
            identifier
        end
    elseif isnumericstart(ch)
        startchar = peek(tz.stream)
        startpos = loc(tz.stream)
        next!(tz.stream)
        content, contentpos = take_while!(tz.stream, isnumericontent)
        token(NUMERIC, startchar * content, startpos * contentpos)
    elseif ch ∈ (keys(CHARTOKENS))
        ch = peek(tz.stream)
        tk = CHARTOKENS[ch]
        lc = location(tz.stream)
        next!(tz.stream)
        token(tk, string(ch), lc)
    elseif ch === ':'
        # Type assert or jlsymbol
        start = loc(tz.stream)
        ch = @next tz.stream "At type assertion or symbol"
        if ch === ':' # Type assert
            next!(tz.stream)
            super = take_identifier!(tz)
            super.type === ERROR && return tz
            value = super.token
            pos = start * super.location
            if peek(tz.stream) === '{'
                params = take_ionic!(tz)
                params.type === ERROR && return params
                value *= params.token
                pos = pos * params.location
            end
            token(TYPEASSERT, value, pos)
        else
            iden = take_identifier!(tz)
            iden.type === ERROR && return iden
            length(iden.token) === 0 && return token(
                ERROR,
                "Expected valid identifier name in symbol",
                Location(loc, loc, tz.stream.file)
            )
            token(SYMBOL, ":" * iden.token, start * iden.location)
        end
    elseif ch === '''
        take_char!(tz)
    elseif ch === '"'
        take_string!(tz)
    elseif ch === '('
        take_ionic!(tz)
    elseif ch === '#'
        startlocation = location(tz.stream)
        next!(tz.stream)
        text, stoploc = take_while!(tz.stream, !=('\n'))
        token(COMMENT, text, startlocation * stoploc)
    else
        tk = token(ERROR, "Unexpected token '$ch'", location(tz.stream))
        next!(tz.stream)
        tk
    end
end


function take_identifier!(tz::Tokenizer)::Token
    startloc = location(tz.stream)
    identifier, lc = stack_while!(tz.stream, Meta.isidentifier)
    return token(IDENTIFIER, identifier, startloc * lc)
end
