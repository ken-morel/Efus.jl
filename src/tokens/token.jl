@enum TokenType begin
    INDENT
end

const Loc = NamedTuple{(:ln, :col), Tuple{UInt, UInt}}

struct Location
    start::Loc
    stop::Loc
    file::AbstractString
end

Base.:*(a::Location, b::Location) = Location(a.start, b.stop, a.file)

const Token = NamedTuple{(:type, :token, :location), Tuple{TokenType, AbstractString, Location}}
