export @efus_str, parseandgenerate

function parseandgenerate(code::String; file::String = "<efus_macro>")
    parser = Parser.EfusParser(code, file)

    ast = Parser.try_parse!(parser)

    return Gen.generate(ast)
end

macro efus_str(code::String)
    file = "<in efus macro at $(__source__.file):$(__source__.line)>"
    generated = parseandgenerate(code; file)

    return quote
        $(LineNumberNode(__source__.line, __source__.file))
        $(esc(generated))
    end
end

macro ionic(expr)
    return Ionic.translate(expr)[1]
end

macro reactor(expr, setter = nothing, usedeps = nothing)
    getter, ionicdeps = Ionic.translate(expr)
    name = gensym(:__radical_reactor__)
    deps = something(usedeps, Expr(:vect, ionicdeps...))
    return esc(
        quote
            let $name = $Reactor(
                    () -> $getter,
                    $setter,
                    $deps
                )
                $name
            end
        end
    )
end
macro radical(expr, usedeps = nothing)
    getter, ionicdeps = Ionic.translate(expr)
    deps = something(usedeps, Expr(:vect, ionicdeps...))
    return esc(
        quote
            let $name = $Reactor(
                    () -> $getter,
                    nothing,
                    $deps
                )
                $catalyze!($getvalue, $Catalyst(), $name)
                $name
            end
        end
    )
end
