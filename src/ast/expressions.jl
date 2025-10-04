struct Julia <: Expression
    value::Any
end

Base.show(io::IO, j::Julia) = printstyled(io, j.value; color = :green)

struct Ionic <: Expression
    expr::Expr
    type::Any
end

struct Vect
    items::Vector{Expression}
end

struct Snippet <: Expression
    args::Vector{Tuple{Symbol, Any}}
    block::Block
end
