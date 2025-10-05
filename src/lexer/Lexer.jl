module Lexer
export print_lexed
using ..Tokens

const Lexed = Vector{Tuple{String, Tokens.TokenType}}

const Style = Dict{Symbol, Any}
const Theme = Dict{Tokens.TokenType, Style}


const EMPTY_THEME = Theme()
const EMPTY_STYLE = Style()

const DEFAULT_THEME = Theme(
    Tokens.ERROR => Style(:bold => true, :color => :red),

    Tokens.INDENT => Style(),
    Tokens.DEDENT => Style(),

    Tokens.EOF => Style(),
    Tokens.EOL => Style(),

    Tokens.IDENTIFIER => Style(:color => :blue),

    Tokens.IONIC => Style(:color => :yellow),
    Tokens.NUMERIC => Style(:color => :magenta),
    Tokens.STRING => Style(:color => :magenta),
    Tokens.CHAR => Style(:color => :magenta),
    Tokens.SYMBOL => Style(:color => :yellow),
    Tokens.SPLAT => Style(:color => :blue),

    Tokens.EQUAL => Style(:color => :cyan),
    Tokens.COMMA => Style(:color => :cyan),

    Tokens.SQOPEN => Style(:color => :cyan),
    Tokens.SQCLOSE => Style(:color => :cyan),

    Tokens.BEGIN => Style(:bold => true, :color => :green),
    Tokens.DO => Style(:bold => true, :color => :green),
    Tokens.FOR => Style(:bold => true, :color => :green),
    Tokens.IF => Style(:bold => true, :color => :green),
    Tokens.ELSE => Style(:bold => true, :color => :green),
    Tokens.ELSEIF => Style(:bold => true, :color => :green),

    Tokens.SNIPPET => Style(:bold => true, :color => :green),

    Tokens.END => Style(:bold => true, :color => :green),

    Tokens.IN => Style(:bold => true, :color => :green),

    Tokens.TYPEASSERT => Style(:color => :cyan),

    Tokens.COMMENT => Style(:italic => true, :color => :light_black),

    Tokens.NONE => EMPTY_STYLE
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
                push!(lexed, (code[index:(start - 1)], Tokens.NONE))
                index = start
            end
            push!(lexed, (code[start:stop], type))
            index = stop + 1
        end
        if index < lastindex(code)
            push!(lexed, (code[index:end], Tokens.NONE))
        end
    end
    try
        Tokens.tokenize!(Tokens.Tokenizer(tokens, Tokens.TextStream(code)))
    catch e
        Base.showerror(stdout, e)
        rethrow()
    end

    return lexed
end

function loc2index(txt::String, loc::Tokens.Loc)::UInt
    newlines = findall('\n', txt)
    pushfirst!(newlines, 1)
    index = newlines[loc.ln]
    return min(index + loc.col - 1, lastindex(txt))
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
