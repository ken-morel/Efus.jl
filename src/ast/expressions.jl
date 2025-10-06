struct Julia <: Expression
    value::Any
end

function show_ast(io::IO, j::Julia; _...)
    return printstyled(io, repr(j.value); STYLE[:expr]...)
end

struct Ionic <: Expression
    expr
    type
end

function show_ast(io::IO, i::Ionic; _...)
    printstyled(io, repr(i.expr); STYLE[:ionic]...)
    if !isnothing(i.type)
        printstyled(io, "::"; STYLE[:sign]...)
        printstyled(io, repr(i.type); STYLE[:ionic]...)
    end
    return
end

struct Vect <: Expression
    items::Vector{Expression}
end

function show_ast(io::IO, v::Vect; context = IdDict())
    :indent ∉ keys(context) && push!(context, :indent => 0)
    ind = "  "^context[:indent]
    printstyled(io, "[\n"; STYLE[:sign]...)
    context[:indent] += 1
    for item in v.items
        print(ind * "  ")
        show_ast(io, item; context = context)
        printstyled(io, ",\n"; STYLE[:sign]...)
    end
    context[:indent] -= 1
    printstyled(io, ind, "]"; STYLE[:sign]...)
    return
end
