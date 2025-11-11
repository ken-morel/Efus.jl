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
