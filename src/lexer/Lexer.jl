"""
Defines a few utilities for colored display
and lexing efus code using the tokenizer.
"""
module Lexer
export print_lexed, lex
using ..Tokens

"""
    const Lexed = Vector{Tuple{String, Tokens.TokenType}}

Lexed represents a list of string contents and their
corresponding tokens. It is returned by [`lex`](@ref).

See also [`Style`](@ref)
"""
const Lexed = Vector{Tuple{String, Tokens.TokenType}}
public Lexed


"""
    const Style = Dict{Symbol, Any}

Represents a dict of keyword arguments passed
to `printstyled`() when displaying the ast.
Though they can also be used elswhere.

See also [`print_lexed`](@ref), [`Theme`](@ref).
"""
const Style = Dict{Symbol, Any}
public Style

"""
    const Theme = Dict{Tokens.TokenType, Style}

A mapping of tokens to their corresponding styles.
"""
const Theme = Dict{Tokens.TokenType, Style}
public Theme


const EMPTY_THEME = Theme()
const EMPTY_STYLE = Style()

const DEFAULT_THEME = Theme(
    Tokens.ERROR => Style(:bold => true, :color => :red, :underline => true),

    # Unstyled
    Tokens.INDENT => EMPTY_STYLE,
    Tokens.DEDENT => EMPTY_STYLE,
    Tokens.EOF => EMPTY_STYLE,
    Tokens.EOL => EMPTY_STYLE,
    Tokens.NONE => EMPTY_STYLE,

    # From AST styles & more distinct colors
    Tokens.IDENTIFIER => Style(:color => :light_blue),
    Tokens._UPPER_IDENTIFIER => Style(:color => :light_green),
    Tokens.JULIAEXPR => Style(:color => :green, :underline => true),
    Tokens.NUMERIC => Style(:color => :light_red),
    Tokens.STRING => Style(:color => :green),
    Tokens.CHAR => Style(:color => :green),
    Tokens.SYMBOL => Style(:color => :yellow),
    Tokens.SPLAT => Style(:color => :light_blue),

    # Operators/Signs
    Tokens.EQUAL => Style(:color => :light_cyan),
    Tokens.COMMA => Style(:color => :cyan),
    Tokens.SQOPEN => Style(:color => :cyan),
    Tokens.SQCLOSE => Style(:color => :cyan),
    Tokens.TYPEASSERT => Style(:color => :yellow),


    # Keywords
    Tokens.BEGIN => Style(:bold => true, :color => :magenta),
    Tokens.FOR => Style(:bold => true, :color => :magenta),
    Tokens.IF => Style(:bold => true, :color => :magenta),
    Tokens.ELSE => Style(:bold => true, :color => :magenta),
    Tokens.ELSEIF => Style(:bold => true, :color => :magenta),
    Tokens.END => Style(:bold => true, :color => :magenta),
    Tokens.IN => Style(:bold => true, :color => :light_magenta),


    # Other
    Tokens.COMMENT => Style(:italic => true, :color => :light_black),
)


"""
    getstyle(theme::Theme, tk::Tokens.TokenType)

Gets the style for the token in the theme, or returns
`EMPTY_STYLE` if there is no such style in the theme.
"""
getstyle(theme::Theme, tk::Tokens.TokenType) = tk in keys(theme) ? theme[tk] : EMPTY_STYLE
public getstyle

"""
    lex(code::AbstractString)

Lexes the code using efus tokenizer and
returns a [`Lexed`](@ref).

See also [`print_lexed`](@ref).
"""
function lex(code::AbstractString)::Lexed
    lexed = Lexed()
    line_index = Tokens.LineIndex(code)
    tokens = Channel{Tokens.Token}() do channel
        index = 1
        for (type, content, loc) in channel
            start = loc2index(line_index, loc.start)
            stop = loc2index(line_index, loc.stop)

            if index < start
                push!(lexed, (code[index:(start - 1)], Tokens.NONE))
            end

            if type == Tokens.EOF
                index = start
                break
            end

            if start > lastindex(code)
                index = start
                continue
            end

            clamped_stop = min(stop, lastindex(code))

            if type === Tokens.IDENTIFIER && length(content) > 0 && isuppercase(content[1])
                type = Tokens._UPPER_IDENTIFIER
            end
            push!(lexed, (code[start:clamped_stop], type))
            index = clamped_stop + 1
        end
        if index <= lastindex(code)
            push!(lexed, (code[index:end], Tokens.NONE))
        end
    end
    tz = Tokens.Tokenizer(Tokens.TextStream(code))
    Tokens.tokenize!(tz, tokens)
    return lexed
end

function print_lexed(io::IO, lexed::Lexed, theme::Theme = DEFAULT_THEME)
    for (text, token_type) in lexed
        style = getstyle(theme, token_type)
        printstyled(io, text; style...)
    end
    return
end

print_lexed(lexed::Lexed, theme::Theme = DEFAULT_THEME) = print_lexed(stdout, lexed, theme)

function print_lexed(io::IO, text::String, theme::Theme = DEFAULT_THEME)
    lexed = lex(text)
    return print_lexed(io, lexed, theme)
end
print_lexed(
    text::String, theme::Theme = DEFAULT_THEME
) = print_lexed(stdout, text, theme)


end
