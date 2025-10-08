"""
Efus parser module defines structures and methods
to parse efus tokens generated from the tokenizer.
"""
module Parser

export EfusParser

using ..Tokens: Tokens, Token, Location, Loc, location, loc, TokenType
import ..Ast
import ..IonicEfus
import ..Lexer


include("./error.jl")
include("./token_stream.jl")

const ENDING = Set{TokenType}([Tokens.EOF, Tokens.EOL, Tokens.COMMENT])
isending(t::Token) = t.type ∈ ENDING

const StatementChannel = Channel{Ast.Statement}

"""
The efus parser structure, takes token
from a [`TokenStream`](@ref) and returns statement.
It has good support for streaming.
"""
mutable struct EfusParser
    stream::TokenStream
    stack::Vector{Ast.Statement}
    root::Ast.Block
    last_statement::Union{Ast.Statement, Nothing}

    """
        EfusParser(input::TokenStream)
        EfusParser(input::Channel{Tokens.Token})
        EfusParser(tokens::Vector{Tokens.Token})

    Creates a parser for the token stream or
    tokens vector.
    """
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

"""
    Base.take!(p::EfusParser, out::StatementChannel)
    Base.take!(p::EfusParser)

Takes the next statement from the parser and either returns
or sends to the channel.
"""
Base.take!(p::EfusParser, out::StatementChannel) = put!(out, take!(p))
Base.take!(p::EfusParser) = take_one!(p)

public take!

"""
    parse!(p::EfusParser, out::Union{StatementChannel, Nothing} = nothing)

A loop which parses the content of the parser and returns the parser's
root block, if `out` is passed, it also sends each received
statement there, where the first sent statement is the parser
root.
"""
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
public parse!


include("./utils.jl")
include("./expression.jl")
include("./statement.jl")


end
