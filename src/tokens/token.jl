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

    SNIPPET

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
    "snippet" => SNIPPET,

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

function Base.:*(a::Location, b::Location)
    @assert(a.file == b.file, "Cannot combine locations in different files $(a) and $(b)")
    return Location(a.start, b.stop, a.file)
end
Base.:*(a::Loc, b::Location) = Location(a, b.stop, b.file)
Base.:*(a::Location, b::Loc) = Location(a.start, b, a.file)

const Token = NamedTuple{(:type, :token, :location), Tuple{TokenType, AbstractString, Location}}
token(t::TokenType, s::AbstractString, l::Location) = Token((t, s, l))

Base.show(io::IO, t::Token) = print(io, string(t.type, "(", t.token, ")"))
