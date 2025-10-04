struct Julia <: Expression
    value::Any
end

struct Ionic <: Expression
    expr::Expr
    type::Any
end

struct Vect
    items::Vector{Expression}
end
