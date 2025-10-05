struct Julia <: Expression
    value::Any
end

function show_ast(io::IO, j::Julia)
    return printstyled(io, j.value; STYLE[:expr]...)
end

struct Ionic <: Expression
    expr
    type
end

function show_ast(io::IO, i::Ionic)
    printstyled(io, i.expr; STYLE[:ionic]...)
    if !isnothing(i.type)
        printstyled(io, "::"; STYLE[:sign]...)
        printstyled(io, i.type; STYLE[:ionic]...)
    end
    return
end

struct Vect
    items::Vector{Expression}
end

struct Snippet <: Expression
    args::Vector{Tuple{Symbol, Any}}
    block::Block
end
