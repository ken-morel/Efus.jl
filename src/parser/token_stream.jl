mutable struct TokenStream
    channel::Channel{Token}

    prev::Union{Token, Nothing}
    current::Union{Token, Nothing}

    TokenStream(taker::Channel{Token}) = new(taker, nothing, nothing)
    TokenStream(fn::Function) = new(Channel{Token}(fn), nothing, nothing)
end
function peek(ts::TokenStream)::Union{Tokens.Token, Nothing}
    if isnothing(ts.current)
        ts.current = try
            take!(ts.channel)
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
