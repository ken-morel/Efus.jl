module Lexer
export print_lexed
using ..Tokens

const Lexed = Vector{Tuple{String, Tokens.TokenType}}

const Style = Dict{Symbol, Any}
const Theme = Dict{Tokens.TokenType, Style}


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
    Tokens.IONIC => Style(:color => :green, :underline => true),
    Tokens.NUMERIC => Style(:color => :light_red),
    Tokens.STRING => Style(:color => :green),
    Tokens.CHAR => Style(:color => :green),
    Tokens.SYMBOL => Style(:color => :yellow),
    Tokens.SPLAT => Style(:color => :light_blue),

    # Operators/Signs
    Tokens.EQUAL => Style(:color => :cyan),
    Tokens.COMMA => Style(:color => :cyan),
    Tokens.SQOPEN => Style(:color => :cyan),
    Tokens.SQCLOSE => Style(:color => :cyan),
    Tokens.TYPEASSERT => Style(:color => :yellow),


    # Keywords
    Tokens.BEGIN => Style(:bold => true, :color => :magenta),
    Tokens.DO => Style(:bold => true, :color => :magenta),
    Tokens.FOR => Style(:bold => true, :color => :magenta),
    Tokens.IF => Style(:bold => true, :color => :magenta),
    Tokens.ELSE => Style(:bold => true, :color => :magenta),
    Tokens.ELSEIF => Style(:bold => true, :color => :magenta),
    Tokens.SNIPPET => Style(:bold => true, :color => :magenta),
    Tokens.END => Style(:bold => true, :color => :magenta),
    Tokens.IN => Style(:bold => true, :color => :magenta),

    # Other
    Tokens.COMMENT => Style(:italic => true, :color => :light_black),
)
@enum TokenType begin
    ERROR

    INDENT
    DEDENT

    EOF
    EOL
    NEXTLINE


    IDENTIFIER

    IONIC
    NUMERIC
    STRING
    CHAR
    SYMBOL
    SPLAT

    EQUAL
    COMMA

    SQOPEN
    SQCLOSE

    BEGIN
    DO
    FOR
    IF
    ELSE
    ELSEIF

    SNIPPET

    END

    IN

    TYPEASSERT

    COMMENT

    NONE
end


getstyle(theme::Theme, tk::Tokens.TokenType) = tk in keys(theme) ? theme[tk] : EMPTY_STYLE

function lex(code::AbstractString)::Lexed
    lexed = Lexed()
    tokens = Channel{Tokens.Token}() do channel
        index = 1
        for (type, _, loc) in channel
            start = loc2index(code, loc.start)
            stop = loc2index(code, loc.stop)

            if index < start
                push!(lexed, (code[index:start - 1], Tokens.NONE))
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
            
            push!(lexed, (code[start:clamped_stop], type))
            index = clamped_stop + 1
        end
        if index <= lastindex(code)
            push!(lexed, (code[index:end], Tokens.NONE))
        end
    end
    Tokens.tokenize!(Tokens.Tokenizer(tokens, Tokens.TextStream(code)))
    return lexed
end

function loc2index(txt::String, loc::Tokens.Loc)::UInt
    loc.ln == 1 && return loc.col
    newlines = findall('\n', txt)
    return newlines[loc.ln - 1] + loc.col
end

function print_lexed(io::IO, lexed::Lexed, theme::Theme = DEFAULT_THEME)
    for (text, token_type) in lexed
        style = getstyle(theme, token_type)
        printstyled(io, text; style...)
    end
    return
end

print_lexed(lexed::Lexed, theme::Theme = DEFAULT_THEME) = print_lexed(stdout, lexed, theme)

function print_lexed(io::IO, text::String, theme::Theme = DEFAULT_THEME; fallback::Bool = true)
    return try
        lexed = lex(text)
        print_lexed(io, lexed, theme)
    catch
        !fallback && rethrow()
        print(io, text)
    end
end
print_lexed(
    text::String, theme::Theme = DEFAULT_THEME; fallback::Bool = true,
) = print_lexed(stdout, text, theme; fallback)


end
