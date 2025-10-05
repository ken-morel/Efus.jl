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
    out::StatementChannel
    stack::Vector{Ast.Statement}
    last_statement::Union{Ast.Statement, Nothing}
    EfusParser(input::TokenStream, output::StatementChannel) = new(input, output, [], nothing)
    EfusParser(input::Channel{Tokens.Token}, output::StatementChannel) = new(TokenStream(input), output, [], nothing)
    EfusParser(tokengetter::Function, output::StatementChannel) = new(TokenStream(tokengetter), output, [], nothing)
end

Base.take!(p::EfusParser) = put!(p.out, take_one!(p))

function parse!(p::EfusParser)
    while true
        statement = take_one!(p)
        isnothing(statement) && break
        put!(p.out, statement)
    end
    close(p.out)
    return
end

include("./utils.jl")
include("./expression.jl")
include("./statement.jl")


end
