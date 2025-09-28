export @efus_str

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
