module Parser

using ..Tokens: Tokens, Token, Location, Loc, location, loc, TokenType
import ..Ast
import ..IonicEfus

const ENDING = Set{TokenType}([Tokens.EOF, Tokens.EOL])
isending(t::Token) = t.type ∈ ENDING

include("./error.jl")
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
function process_indent!(p::EfusParser)
    tk = peek(p.stream)
    ts = p.stream
    if tk.type === Tokens.INDENT
        isempty(p.stack) && ParseError("Unexpected indent", tk.location)
    elseif tk.type === Tokens.DEDENT
        while tk.type === Tokens.DEDENT
            pop!(p.stack)
            tk = next!(ts)
        end
    end
    return if !isempty(p.stack)
        p.stack[end]
    end
end
function take_one!(p::EfusParser)
    ts = p.stream
    parent = process_indent!(p)
    token = peek(ts)
    return if token.type === Tokens.IDENTIFIER
        statement = Ast.ComponentCall(; parent, componentname = Symbol(token.token))
        # Component call
        next!(ts)
        while true
            tk = peek(ts)
            isending(tk) && break
            shouldbe(tk, [Tokens.IDENTIFIER], "In component call, expeted argument name")
            paramname = Symbol(tk.token)
            nx = next!(ts)
            if nx.type === Tokens.SPLAT
                push!(statement.splats, Symbol(tk.token))
                next!(ts)
                continue
            end
            paramsub = if nx.type === Tokens.SYMBOL
                n = nx.token
                nx = next!(ts)
                Symbol(n[2:end])
            end
            shouldbe(nx, [Tokens.EQUAL], "After component call argument name, expected equal, got '$(nx.token)'")
            next!(ts)
            paramvalue = take_expression!(p)
            isnothing(paramvalue) && throw(ParseError("Expected value", peek(ts).location))
            push!(statement.arguments, (paramname, paramsub, paramvalue))
            isending(peek(ts)) && break
        end
        statement
    end
end
const DIRECT_EVAL = [Tokens.IDENTIFIER, Tokens.NUMERIC, Tokens.STRING, Tokens.CHAR, Tokens.SYMBOL]
function take_expression!(p::EfusParser)::Ast.Expression
    tk = peek(p.stream)
    ts = p.stream
    return if tk.type === Tokens.IONIC
        nx = next!(ts)
        expr = Meta.parse(tk.token)
        type = if nx.type === Tokens.TYPEASSERT
            next!(ts)
            Meta.parse(nx.token)
        end
        Ast.Ionic(expr, type)
    elseif tk.type ∈ DIRECT_EVAL
        next!(ts)
        expr = Meta.parse(tk.token)
        Ast.Julia(expr)
    end
end

function shouldbe(tk::Token, tkt::Vector{TokenType}, wh::String)
    return if tk.type ∉ tkt
        throw(ParseError("Unexpected token($(tk.type)) $wh", tk.location))
    else
        tk
    end
end
end
