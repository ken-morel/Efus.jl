export TokenType, Token, Tokenizer, token, Loc, Location
"""
  Simply an enum which contains supported
  types of tokens. All tokens are parser
  tokens, except the _ preceded ones which
  are lexer tokens, and not returned by the
  tokenizer.
"""
@enum TokenType begin
    ERROR

    INDENT
    DEDENT

    EOF
    EOL


    IDENTIFIER
    _UPPER_IDENTIFIER

    JULIAEXPR
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
    FOR
    IF
    ELSE
    ELSEIF

    END

    IN

    TYPEASSERT

    COMMENT

    NONE
end


const CHARTOKENS = Dict{Char, TokenType}(
    '=' => EQUAL,
    '[' => SQOPEN,
    ']' => SQCLOSE,
    ',' => COMMA,
)
const KEYWORDS = Dict{String, TokenType}(
    "begin" => BEGIN,
    "end" => END,
    "for" => FOR,
    "if" => IF,
    "else" => ELSE,
    "elseif" => ELSEIF,

    "in" => IN,
    "∈" => IN,
)

"""
    const Loc = @NamedTuple{ln::UInt, col::UInt}

Loc represents a line column tuple. It is constructed
via [`loc`](@ref).
"""
const Loc = @NamedTuple{ln::UInt, col::UInt}
"""
    loc(a::Integer, b::Integer)

Constructs a [`Loc`](@ref) object.
"""
loc(a::Integer, b::Integer) = Loc((a, b))

"""
    struct Location

A location, holding start, stop of type [`Loc`](@ref) and
file.
"""
struct Location
    start::Loc
    stop::Loc
    file::AbstractString
end

"""
    show_location(io::IO, loc::Location)

Words the location to io.
"""
function show_location(io::IO, loc::Location)
    if loc.start.ln === loc.stop.ln
        print(io, "At line $(loc.start.ln)")
    else
        print(io, "Between lines $(loc.start.ln) and $(loc.stop.ln)")
    end
    if loc.start.col === loc.stop.col
        print(io, ", column $(loc.start.col)")
    else
        print(io, ", between columns $(loc.start.col) and $(loc.stop.col)")
    end
    print(", in file $(loc.file)")
    return
end
public show_location

"""
    Base.:*(a::Location, b::Location)
    Base.:*(a::Loc, b::Location)
    Base.:*(a::Location, b::Loc)

Concatense the two locations or [`Loc`](@ref) to create
a bigger [`Location`](@ref)
"""
function Base.:*(a::Location, b::Location)
    @assert(a.file == b.file, "Cannot combine locations in different files $(a) and $(b)")
    return Location(a.start, b.stop, a.file)
end
Base.:*(a::Loc, b::Location) = Location(a, b.stop, b.file)
Base.:*(a::Location, b::Loc) = Location(a.start, b, a.file)

"""
    const Token = @NamedTuple{type::TokenType, token::String, location::Location}

A tokenizer token. Constructed via [`token`](@ref).

See also [`TokenType`](@ref), [`Location`](@ref).
"""
const Token = @NamedTuple{type::TokenType, token::String, location::Location}

"""
    token(t::TokenType, s::AbstractString, l::Location)

Creates a [`Token`](@ref).
"""
token(t::TokenType, s::AbstractString, l::Location) = Token((t, s, l))

Base.show(io::IO, t::Token) = print(io, string(t.type, "(", t.token, ")"))
