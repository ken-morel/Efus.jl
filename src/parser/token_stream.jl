"""
    mutable struct TokenStream

A tokenstream feeds tokens from a channel
of function to a parser.
"""
mutable struct TokenStream
    channel::Channel{Token}

    prev::Union{Token, Nothing}
    current::Union{Token, Nothing}

    """
        TokenStream(taker::Channel{Token})
        TokenStream(tokens::Vector{Token})

    Constructs a tokenstream from a channel of tokens or
    a list of tokens.
    """
    TokenStream(taker::Channel{Token}) = new(taker, nothing, nothing)
end
function TokenStream(tokens::Vector{Token})
    chan = Channel{Token}(length(tokens))
    put!((chan,), tokens)
    close(chan)
    return TokenStream(chan)
end
public TokenStream
function peek(ts::TokenStream)::Union{Tokens.Token, Nothing}
    if isnothing(ts.current)
        ts.current = try
            tk = take!(ts.channel)
            while tk.type === Tokens.COMMENT
                tk = take!(ts.channel)
            end
            tk
        catch e
            if !isa(e, InvalidStateException)
                rethrow(e)
            end
        end
    end
    return ts.current
end

function next!(ts::TokenStream)::Union{Tokens.Token, Nothing}
    st = peek(ts)
    return if !isnothing(st)
        ts.prev = st
        ts.current = try
            c = take!(ts.channel)
            while !isnothing(c) && c.type === Tokens.COMMENT
                c = take!(ts.channel)
            end
            !isnothing(c) && c.type === Tokens.ERROR && throw(ParseError(c.token, c.location))
            c
        catch e
            if !isa(e, InvalidStateException)
                rethrow(e)
            end
        end
    end
end

function Base.take!(ts::TokenStream, amongst::Vector{Tokens.TokenType}, wh::String)
    nxt = next!(ts)
    return if nxt.type ∈ amongst
        nxt
    else
        throw(ParseError("Unexpected token $wh", nxt.location))
    end
end
