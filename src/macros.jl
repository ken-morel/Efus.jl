export @efus_str, @reactor, @ionic, @radical


"""
    macro efus_str(code::String)

Receives the code as argument, then 
tokenizes, parses and generates julia 
code.
"""
macro efus_str(code::String)
    file = "<macro at $(__source__.file):$(__source__.line)>"

    generated = Gen.generate(parse_efus(code, file))

    return quote
        $(LineNumberNode(__source__.line, __source__.file))
        $(esc(generated))
    end
end

"""
    macro ionic(expr)

Converts the given `ionic` expression to 
the julia getter code.
The code returns the evaluated expression.

See also [`@reactor`](@ref)
"""
macro ionic(expr)
    return esc(IonicEfus.Ionic.transcribe(expr)[1])
end

"""
    macro reactor(expr, setter = nothing, usedeps = nothing)

Shorcut for creating a reactor, with optional setter.
It accepts ionic expressions for both. The 
generated expression returns a lazily evaluated [`Reactor`](@ref).
If the getter expression is a typeassert the type 
will be used to cast to the reactor.

See also [`@radical`](@ref)
"""
macro reactor(expr, setter = nothing, usedeps = nothing)
    expr, type = if expr isa Expr && expr.head == :(::)
        expr.args
    else
        expr, :Any
    end
    getter, ionicdeps = IonicEfus.Ionic.transcribe(expr)
    setter = if !isnothing(setter)
        IonicEfus.Ionic.transcribe(setter)[1]
    end
    deps = something(usedeps, Expr(:vect, ionicdeps...))
    return esc(
        :(
            IonicEfus.Reactor{$type}(
                () -> $getter,
                $setter,
                $deps
            )
        )
    )
end

"""
    macro radical(expr,  usedeps = nothing, setter = nothing)

Creates an expression which re-evaluates directly when 
it's dependencies change, agnostic to svelte's \$: {}.
Returns the underlying eagerly evaluated [`Reactor`](@ref).
The setter and usedeps can be put in any direction.

See also [`@reactor`](@ref)
"""
macro radical(expr, usedeps = nothing, setter = nothing)
    expr, type = if expr isa Expr && expr.head == :(::)
        expr.args
    else
        expr, :Any
    end
    getter, ionicdeps = IonicEfus.Ionic.transcribe(expr)
    setter = if !isnothing(setter)
        IonicEfus.Ionic.transcribe(setter)[1]
    end
    deps = something(usedeps, Expr(:vect, ionicdeps...))
    return esc(
        :(
            IonicEfus.Reactor{$type}(
                () -> $getter,
                $setter,
                $deps;
                eager = true,
            )
        )
    )
end
