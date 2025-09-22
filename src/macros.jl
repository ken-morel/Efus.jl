export @efus

macro efus(code::String)
    # 1. Create an instance of your parser
    parser = Parser.EfusParser(code, "<efus_macro>")

    # 2. Parse the code to get the AST
    ast = Parser.try_parse!(parser)

    # 3. Pass the AST to the generator to get the final Julia Expression
    generated_code = Gen.generate(ast)

    # 4. Return the generated code, escaping it so variables are resolved in the caller's scope.
    return esc(generated_code)
end