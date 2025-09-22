module Parser

using ...Efus: EfusError, Geometry, Size
import ..Ast


mutable struct EfusParser
    text::String
    file::String
    index::UInt
    stack::Vector{Tuple{Int, Ast.AbstractStatement}}


    EfusParser(text::String, file::String) = new(text, file, 1, [(-1, Ast.Block([]))])
end


include("./error.jl")
include("./location.jl")
include("./utils.jl")

include("./string.jl")
include("./geometry.jl")
include("./compcall.jl")
include("./jexpr.jl")
include("./expression.jl")


function parse!(p::EfusParser)::Union{Ast.Block, AbstractParseError}
    root_block = p.stack[1][2]
    @assert root_block isa Ast.Block "Parser stack was not initialized with a root Block."

    statement = nothing
    while true
        skip_emptylines!(p) || break

        @zig! statement parse_statement!(p)
        isnothing(statement) && break
        indent, statement = statement

        # Pop items from the stack that are no longer parents
        while length(p.stack) > 1 && p.stack[end][1] >= indent
            pop!(p.stack)
        end

        # The parent is the last item on the stack
        (_, parent) = p.stack[end]
        if parent !== root_block # Don't set parent for top-level items
            statement.parent = parent
        end
        push!(parent.children, statement)

        # The new statement is now a potential parent
        push!(p.stack, (indent, statement))
    end
    return root_block
end
function skip_emptylines!(p::EfusParser)
    while inbounds(p)
        line_start = p.index
        line_end = findnext(==('\n'), p.text, line_start)

        if isnothing(line_end)
            if all(isspace, p.text[line_start:end])
                p.index = length(p.text) + 1
            end
            break
        else
            if all(isspace, p.text[line_start:line_end])
                p.index = line_end + 1
            else
                break
            end
        end
    end
    return inbounds(p)
end

function parse_statement!(p::EfusParser)::Union{Tuple{UInt, Ast.AbstractStatement}, Nothing, AbstractParseError}
    return ereset(p) do
        indent = skip_spaces!(p)
        statement = nothing
        @zig!n statement parse_componentcall!(p)
        return (indent, statement)
    end
end


const SYMBOL = r"\w[\w\d]*"
function parse_symbol!(p::EfusParser)::Union{Symbol, Nothing}
    inbounds(p) || return nothing
    m = match(SYMBOL, p.text, p.index)
    return if !isnothing(m) && m.offset == p.index
        p.index += length(m.match)
        Symbol(m.match)
    end
end

end
