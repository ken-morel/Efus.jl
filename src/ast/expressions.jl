struct Julia <: Expression
    value::Any
end

struct Ionic <: Expression
    expr
    type
end

struct Vect <: Expression
    items::Vector{Expression}
end
