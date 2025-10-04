module Parser

using ..Tokens: Tokens, Token
import ..Ast

include("./token_stream.jl")

const StatementChannel = Channel{Ast.Statement}

mutable struct EfusParser
    stream::TokenStream
    out::StatementChannel

    stack::Vector{Ast.Statement}

    EfusParser(input::TokenStream, output::StatementChannel) = new(input, output, [])
end

Base.take!(p::EfusParser) = put!(p.out, take_one!(p))
function parse!(p::EfusParser)
    while true
        isnothing(take!(p)) && break
    end
    return
end
function take_indent!(p::EfusParser)
end
function take_one!(p::EfusParser)
    ts = p.stream
    token = peek(ts)
    return
end

end
