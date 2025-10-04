mutable struct TokenStream
    take::Function

    prev::Union{Token, Nothing}
    current::Union{Token, Nothing}

    TokenStream(taker::Function) = new(taker, nothing, nothing)
end

function TokenStream(c::Channel{Token})
    return TokenStream() do
        try
            take!(c)
        catch e
            if !isa(e, InvalidStateException)
                rethrow(e)
            end
        end
    end
end
