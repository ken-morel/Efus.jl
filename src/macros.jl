export @efus

macro efus(code::String)
    parser = Parser.EfusParser(code, "<efus_macro>")

    ast = Parser.try_parse!(parser)

    generated_code = Gen.generate(ast)

    return quote
        () -> $(esc(generated_code))
    end
end

