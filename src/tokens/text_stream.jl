export TextStream

"""
    mutable struct TextStream

A TextStream object handles the 
text input stream for the tokenizer. 
It uses it's different methods to 
wrap on different kind of inputs.
"""
mutable struct TextStream
    io::IO

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
    TextStream(io::IO, file::String = "<taken>") = new(io, file, nothing, nothing, 1, 1)
end

"""
    TextStream(s::String, file::String = "<string>")

Constructs a TextStream object from a string, whith 
support for julia multicode characters.
"""
TextStream(s::String, file::String = "<string>") = TextStream(IOBuffer(s), file)

"""
    peek(ts::TextStream)::Union{Char, Nothing}

Read the current character in text stream.
"""
function peek(ts::TextStream)::Union{Char, Nothing}
    if isnothing(ts.current)
        ts.current = try
            read(ts.io, Char)
        catch e
            if !isa(e, EOFError)
                rethrow(e)
            end
        end
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
        ts.current = try
            read(ts.io, Char)
        catch e
            if !isa(e, EOFError)
                rethrow(e)
            end
        end
    end
end

"""
    Base.take!(ts::TextStream, expected::Char)::Union{Char, Nothing}

Return the next character if the current character is `expected`.
"""
function Base.take!(ts::TextStream, expected::Char)::Union{Char, Nothing}
    if peek(ts) == expected
        return next!(ts)
    end
end

"""
    take_while!(ts::TextStream, predicate::Function)::Tuple{String, Location}
    take_while!(fn::Function, ts::TextStream)

Collects the next character and return them as a string as 
long as predicate is true, and return the collected string.

See also [`skip_while!`](@ref)
"""
function take_while!(ts::TextStream, predicate::Function)::Tuple{String, Location}
    buffer = IOBuffer()
    start = loc(ts)
    stop = start
    while true
        char = peek(ts)
        if !isnothing(char) && predicate(char)
            write(buffer, char)
            stop = loc(ts)
            next!(ts)
        else
            break
        end
    end
    return String(take!(buffer)), Location(start, stop, ts.file)
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
        else
            break
        end
    end
    return
end
skip_while!(fn::Function, ts::TextStream) = skip_while!(ts, fn)

"Returns true if the text stream is at end of input"
eof(ts::TextStream) = isnothing(peek(ts))

"Returns true if the text stream is on a newline or end of input"
eol(ts::TextStream) = eof(ts) || peek(ts) === '\n'

"Get the current location of the stream as a [`Loc`](@ref)"
loc(ts::TextStream) = loc(ts.ln, ts.col)

"Get the current location of a file as a [`Location`](@ref)"
location(ts::TextStream) = Location(loc(ts), loc(ts), ts.file)

"Get if the text stream is at the begining of the file"
bof(ts::TextStream) = isnothing(ts.prev)
"Get if the stream is at the begining of a line, or of the file"
bol(ts::TextStream) = bof(ts) || ts.prev === '\n'

"Call's the function `fn` on the current char"
test(fn::Function, ts::TextStream) = fn(peek(ts))
test(ts::TextStream, fn::Function) = test(fn, ts)

"""
    stack_while!(ts::TextStream, predicate::Function)::Union{String, Loc}
    stack_while!(fn::Function, ts::TextStream)

Creates a string with the current character, and 
continues taking and appending to the string as 
long as predicate returns true. And returns the location
containing the taken string.
"""
function stack_while!(ts::TextStream, predicate::Function)::Tuple{String, Location}
    #PERF: May be a buffer will be better.
    # But it involves simply creating new strings, so...
    final = ""
    temp = string(peek(ts))
    start = loc(ts)
    stop = start
    while predicate(temp)
        final = temp
        stop = loc(ts)
        nx = next!(ts)
        isnothing(nx) && break
        temp *= nx
    end
    return final, Location(start, stop, ts.file)
end

stack_while!(fn::Function, ts::TextStream) = stack_while!(ts, fn)
