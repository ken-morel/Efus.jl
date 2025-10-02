"""
    Base.@kwdef struct Tokenizer

The efus code tokenizer.
Reads characters from a [`TextStream`](@ref), which can 
wrap channels, IO, or strings and outputs 
by calling an output function.
"""
struct Tokenizer
    out::Function
    stream::TextStream
    pending::Vector{Token}
    indents::Vector{UInt}
    """
        Tokenizer(out::Function, stream::TextStream)

    # Arguments
    - `out::Function`: The output function which will be called with every new 
      [`Token`](@ref).
    - `stream::TextStream`: The [`TextStream`](@ref) for the tokenizer to read from.

    See also [`tokenize!`](@ref).
    """
    Tokenizer(out::Function, stream::TextStream) = new(out, stream, [], [])

end

Tokenizer(
    out::Channel{Token}, stream::TextStream,
) = Tokenizer(stream) do token
    put!(out, token)
end

function tokenize!(tz::Tokenizer)
end
