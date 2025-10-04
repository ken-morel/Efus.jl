struct Julia <: Expression
    value::Any
end

struct Ionic <: Expression
    expr::Expr
    type::Union{Nothing, Some}
end

struct Vect
    items::Vector{Expression}
end
