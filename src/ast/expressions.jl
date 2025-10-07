struct Julia <: Expression
    expr
end

struct Reactor <: Expression
    expr
    type
end

struct Vect <: Expression
    items::Vector{Expression}
end
