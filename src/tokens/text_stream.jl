"""
    mutable struct TextStream

A TextStream object handles the 
text input stream for the tokenizer. 
It uses it's different methods to 
wrap on different kind of inputs.
"""
mutable struct TextStream
    take::Function

    file::String

    prev::Union{Char, Nothing}
    current::Union{Char, Nothing}

    ln::UInt
    col::UInt
    """
        TextStream(take::Function, file::String = "<taken>")


    The default and only inner constructor. 
    It accepts a `take` function which returns the next 
    character in stream, or nothing if input finished.
    Another optional argument, `file` helps for stacktraces.
    """
    TextStream(take::Function, file::String = "<taken>") = new(take, file, nothing, nothing, 1, 1)
end

"""
    TextStream(c::Channel{Char}, file::String = "<channel>")

Constructs a TextStream by wrapping on a channel of characters.
The getter correctly signals with nothing to the textstream when the 
channel is closed.
"""
function TextStream(c::Channel{Char}, file::String = "<channel>")
    return TextStream(file) do
        try
            take!(c)
        catch e
            if !isa(e, InvalidStateException)
                rethrow(e)
            end
        end
    end
end

"""
    TextStream(io::IO, file::String = "<io>")

Creates a TextStream from an IO object like a 
file, or so similar.
"""
function TextStream(io::IO, file::String = "<io>")
    return TextStream(file) do
        try
            return read(io, Char)
        catch e
            if !isa(e, EOFError)
                rethrow(e)
            end
        end
    end
end

"""
    TextStream(s::String, file::String = "<string>")

Constructs a TextStream object from a string, whith 
support for julia multicode characters.
"""
function TextStream(s::String, file::String = "<string>")
    current_idx = Ref(firstindex(s))
    return TextStream(file) do
        if current_idx[] <= lastindex(s)
            char = s[current_idx[]]
            current_idx[] = nextind(s, current_idx[])
            char
        end
    end
end


"""
    peek(ts::TextStream)::Union{Char, Nothing}

Read the current character in text stream.
"""
function peek(ts::TextStream)::Union{Char, Nothing}
    if isnothing(ts.current) # Start of File
        ts.current = ts.take()
    end
    return ts.current
end

"""
    next!(ts::TextStream)

Advance and read the next character in stream.
"""
function next!(ts::TextStream)::Union{Char, Nothing}
    char = peek(ts)
    return if !isnothing(char)
        ts.prev = char
        if char == '\n'
            ts.ln += 1
            ts.col = 1
        else
            ts.col += 1
        end
        ts.current = ts.take()
    end
end

"""
    take!(ts::TextStream, expected::Char)::Union{Char, Nothing}

Return the next character if the current character is `expected`.
"""
function Base.take!(ts::TextStream, expected::Char)::Union{Char, Nothing}
    if peek(ts) == expected
        return next!(ts)
    end
end

"""
    take_while!(ts::TextStream, predicate::Function)::String
    take_while!(fn::Function, ts::TextStream)

Collects the next character and return them as a string as 
long as predicate is true, and return the collected string.

See also [`skip_while!`](@ref)
"""
function take_while!(ts::TextStream, predicate::Function)::String
    buffer = IOBuffer()
    while true
        char = peek(ts)
        if !isnothing(char) && predicate(char)
            write(buffer, char)
            next!(ts)
        end
    end
    return String(take!(buffer))
end
take_while!(fn::Function, ts::TextStream) = take_while!(ts, fn)

"""
    skip_while!(ts::TextStream, predicate::Function)
    skip_while!(fn::Function, ts::TextStream)

Does like [`take_while!`](@ref) and skips characters while 
predicate returns true, except it does not store the 
skipped characters.
"""
function skip_while!(ts::TextStream, predicate::Function)
    while true
        char = peek(ts)
        if !isnothing(char) && predicate(char)
            next!(ts)
        end
    end
    return
end
skip_while!(fn::Function, ts::TextStream) = skip_while!(ts, fn)

"Returns true if the text stream is at end of input"
eof(ts::TextStream) = isnothing(peek(ts))

"Returns true if the text stream is on a newline or end of input"
eol(ts::TextStream) = eof(ts) || peek(ts) === '\n'

"Get the current loc (ln, col) tuple of the text stream"
loc(ts::TextStream) = Loc(ts.ln, ts.col)

"Get if the text stream is at the begining of the file"
bof(ts::TextStream) = isnothing(ts.prev)
"Get if the stream is at the begining of a line, or of the file"
bol(ts::TextStream) = bof(ts) || ts.prev === '\n'
