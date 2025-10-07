module Parser

using ..Tokens: Tokens, Token, Location, Loc, location, loc, TokenType
import ..Ast
import ..IonicEfus
import ..Lexer


include("./error.jl")
include("./token_stream.jl")

const ENDING = Set{TokenType}([Tokens.EOF, Tokens.EOL])
isending(t::Token) = t.type ∈ ENDING


const StatementChannel = Channel{Ast.Statement}

mutable struct EfusParser
    stream::TokenStream
    stack::Vector{Ast.Statement}
    root::Ast.Block
    last_statement::Union{Ast.Statement, Nothing}
    function EfusParser(input::TokenStream)
        return new(input, [], Ast.Block(), nothing)
    end
end
EfusParser(input::Channel{Tokens.Token}) = EfusParser(TokenStream(input))

function EfusParser(tokens::Vector{Tokens.Token})
    ch = Channel{Token}(length(tokens))
    for token in tokens
        put!(ch, token)
    end
    close(ch)
    return EfusParser(ch)
end

Base.take!(p::EfusParser, out::StatementChannel) = put!(out, take!(p))
Base.take!(p::EfusParser) = take_one!(p)

function parse!(p::EfusParser, out::Union{StatementChannel, Nothing} = nothing)
    isnothing(out) || put!(out, p.root)
    try
        while true
            statement = take_one!(p)
            isnothing(statement) && break
            isnothing(out) || put!(out, statement)
            Ast.affiliate!(statement)
        end
    finally
        isnothing(out) || close(out)
    end
    return p.root
end

include("./utils.jl")
include("./expression.jl")
include("./statement.jl")


end
