module Lexer
using ..Tokens

const Lexed = Vector{Tuple{String, Tokens.Token}}

const Style = Dict{Symbol, Any}
const Theme = Dict{Tokens.Token, Style}

const DEFAULT_THEME = Theme()

const EMPTY_THEME = Theme()
const EMPTY_STYLE = Style()


getstyle(theme::Theme, tk::Tokens.Token) = tk in keys(theme) ? theme[tk] : EMPTY_STYLE

function lex(code::AbstractString)::Lexed
    lexed = Lexed()
    index = 1
    tokens = Channel{Tokens.Token}() do channel
        for (type, _, loc) in channel
        end
    end
    Tokens.tokenize!(Tokens.Tokenizer(tokens, Tokens.TextStream(code)))
    return lexed
end


end
