export TokenType, Token, Tokenizer, token, Loc, Location
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

    END

    IN

    TYPEASSERT

    COMMENT
end


const CHARTOKENS = Dict{Char, TokenType}(
    '=' => EQUAL,
    '[' => SQOPEN,
    ']' => SQCLOSE,
    ',' => COMMA,
    '|' => NEXTLINE
)
const KEYWORDS = Dict{String, TokenType}(
    "begin" => BEGIN,
    "end" => END,
    "do" => DO,
    "for" => FOR,
    "if" => IF,
    "else" => ELSE,
    "elseif" => ELSEIF,

    "in" => IN,
    "∈" => IN,
)


const Loc = NamedTuple{(:ln, :col), Tuple{UInt, UInt}}
loc(a::Integer, b::Integer) = Loc((a, b))

struct Location
    start::Loc
    stop::Loc
    file::AbstractString
end

function Base.:*(a::Location, b::Location)
    @assert(a.file == b.file, "Cannot combine locations in different files $(a) and $(b)")
    return Location(a.start, b.stop, a.file)
end
Base.:*(a::Loc, b::Location) = Location(a, b.stop, b.file)
Base.:*(a::Location, b::Loc) = Location(a.start, b, a.file)

const Token = NamedTuple{(:type, :token, :location), Tuple{TokenType, AbstractString, Location}}
token(t::TokenType, s::AbstractString, l::Location) = Token((t, s, l))

Base.show(io::IO, t::Token) = print(io, string(t.type, "(", t.token, ")"))
