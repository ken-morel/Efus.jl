module Parser

using ...Efus: EfusError, Geometry, Size
import ..Ast


mutable struct EfusParser
    text::String
    file::String
    index::UInt
    stack::Vector{Tuple{UInt, Ast.AbstractStatement}}

    EfusParser(text::String, file::String) = new(text, file, 1, Ast.AbstractStatement[])
end


include("./error.jl")
include("./location.jl")
include("./utils.jl")

include("./string.jl")
include("./geometry.jl")
include("./expression.jl")
include("./compcall.jl")


function parse!(p::EfusParser)::Union{Ast.Block, AbstractParseError}
    children = Ast.AbstractStatement[]
    statement = nothing
    while true
        @zig! statement parse_statement!(p)
        isnothing(statement) && break
        push!(children, statement)
    end
    return Ast.Block(children)
end

function parse_statement!(p::EfusParser)::Union{Ast.AbstractStatement, Nothing, AbstractParseError}
    return parse_componentcall!(p)
end


function parse_symbol!(p::EfusParser)::Union{Symbol, Nothing}
    m = match(r"\w[\w\d]*", p.text, p.index)
    return if !isnothing(m) && m.offset == p.index
        p.index += length(m.match)
        Symbol(m.match)
    end
end

end
