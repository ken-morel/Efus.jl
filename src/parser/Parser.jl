module Parser
export EfusParser, try_parse!, parse!

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

include("./compcall.jl")
include("./control.jl")

include("./string.jl")
include("./geometry.jl")
include("./jexpr.jl")
include("./expression.jl")
include("./snippet.jl")


function parse!(p::EfusParser)::Union{Ast.Block, AbstractParseError}
    root_block = p.stack[1][2]
    @assert root_block isa Ast.Block "Parser stack was not initialized with a root Block."

    while true
        skip_emptylines!(p) || break

        statement = @zig! parse_statement!(p)
        isnothing(statement) && break
        indent, statement = statement

        while length(p.stack) > 1 && p.stack[end][1] >= indent
            pop!(p.stack)
        end

        (_, parent) = p.stack[end]
        if parent !== root_block
            statement.parent = parent
        end
        push!(parent.children, statement)

        push!(p.stack, (indent, statement))
    end
    return root_block
end
subparse!(p::EfusParser, code::String, loc::String) = parse!(
    EfusParser(code, p.file * "; " * loc),
)
function parse_statement!(p::EfusParser)::Union{Tuple{UInt, Ast.AbstractStatement}, Nothing, AbstractParseError}
    return ereset(p) do
        indent = skip_spaces!(p)
        control = @zig! parse_controlflow!(p)
        !isnothing(control) && return (indent, control)
        statement = @zig! parse_juliablock!(p)
        !isnothing(statement) && return (indent, statement)
        statement = @zig! parse_componentcall!(p)
        !isnothing(statement) && return (indent, statement)
        return
    end
end

end
