export @efus_str, @reactor, @ionic, @radical


macro efus_str(code::String)
    file = "<in efus macro at $(__source__.file):$(__source__.line)>"

    generated = Gen.generate(IonicEfus.parse_efus(code, file))

    return quote
        $(LineNumberNode(__source__.line, __source__.file))
        $(esc(generated))
    end
end

"""
    macro ionic(expr)

Converts the given `ionic` expression to 
the julia getter code.
"""
macro ionic(expr)
    return esc(IonicEfus.Ionic.translate(expr)[1])
end

"""
    macro reactor(expr, setter = nothing, usedeps = nothing)

Shorcut for creating a reactor, with optional setter.
It accpets ionic expressions for both.
"""
macro reactor(expr, setter = nothing, usedeps = nothing)
    getter, ionicdeps = IonicEfus.Ionic.translate(expr)
    setter = if !isnothing(setter)
        IonicEfus.Ionic.translate(setter)[1]
    end
    deps = something(usedeps, Expr(:vect, ionicdeps...))
    return esc(
        :(
            IonicEfus.Reactor(
                () -> $getter,
                $setter,
                $deps
            )
        )
    )
end

"""
    macro radical(expr, usedeps = nothing)

Creates an expression which re-evaluates directly when 
it's dependencies change, agnostic to svelte's \$: {}.
Returns the underlying Reactor.
"""
macro radical(expr, usedeps = nothing)
    getter, ionicdeps = IonicEfus.Ionic.translate(expr)
    deps = something(usedeps, Expr(:vect, ionicdeps...))
    return esc(
        :(
            IonicEfus.Reactor(
                () -> $getter,
                nothing,
                $deps;
                eager = true
            )
        )
    )
end
