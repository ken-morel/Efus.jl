mutable struct TokenStream
    channel::Channel{Token}

    prev::Union{Token, Nothing}
    current::Union{Token, Nothing}

    TokenStream(taker::Channel{Token}) = new(taker, nothing, nothing)
    TokenStream(fn::Function) = new(Channel{Token}(fn), nothing, nothing)
end
function peek(ts::TokenStream)::Union{Ast.Statement, Nothing}
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

function next!(ts::TokenStream)::Union{Ast.Statement, Nothing}
    st = peek(ts)
    return if !isnothing(st)
        ts.prev = st
        ts.current = try
            take!(ts.channel)
        catch e
            if !isa(e, InvalidStateException)
                rethrow(e)
            end
        end
        !isnothing(ts.current) && ts.current.type == Tokens.ERROR && error(ts.current.token)
    end
end
