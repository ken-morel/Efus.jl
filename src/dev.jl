"""
    module Dev

Development utilities to debug code.
"""
module Dev

using ..Parser
using ..Gen
using MacroTools

export codegen_string

"""
    codegen_string(code::String)

Parses a string of Efus code, generates the corresponding Julia expression,
and returns it as a formatted, human-readable string.

This is a utility for debugging and inspection.

# Examples
```julia
julia> Efus.codegen_string("Frame\n  Label")
\"""
Frame(children = [Label()])
\"""
```
"""
function codegen_string(code::String)
    parser = Parser.EfusParser(code, "<string>")
    ast = Parser.try_parse!(parser)
    expr = Gen.generate(ast)
    pretty_expr = MacroTools.prettify(expr)
    return string(pretty_expr)
end

end # module Dev
