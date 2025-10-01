export @efus_str, parseandgenerate


"""
    function parseandgenerate(code::String; file::String = "<efus_macro>")

Parses the passed string, and returns the parsed Ast block or 
throws an IonicEfus.EfusError.
"""
function parseandgenerate(code::String; file::String = "<efus_macro>")
    parser = IonicEfus.Parser.EfusParser(code, file)

    ast = IonicEfus.Parser.try_parse!(parser)

    return IonicEfus.Gen.generate(ast)
end

"""
    macro efus_str(code::String)

Parses efus code and generates corresponding julia 
code at macro expantion time.
"""
macro efus_str(code::String)
    file = "<in efus macro at $(__source__.file):$(__source__.line)>"
    generated = parseandgenerate(code; file)

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
    return IonicEfus.Ionic.translate(expr)[1]
end

"""
    macro reactor(expr, setter = nothing, usedeps = nothing)

Shorcut for creating a reactor, with optional setter.
It accpets ionic expressions for both.
"""
macro reactor(expr, setter = nothing, usedeps = nothing)
    getter, ionicdeps = IonicEfus.Ionic.translate(expr)
    setter = if !isnothing(setter)
        IonicEfus.Ionic.translate(expr)[1]
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
