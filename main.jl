# A script to manually test the Efus compiler pipeline

# Load the Efus module
include("src/Efus.jl")
using .Efus
using MacroTools # For pretty-printing expressions

# 1. Define some sample Efus code
# (We'll keep it simple since the parser is still basic)
efus_code = """
Frame padding=3x3
  Label text="Hello world" args...
  Button
"""

println("--- 1. Efus Input ---")
println(efus_code)
println()

# 2. Manually parse the code
parser = Efus.Parser.EfusParser(efus_code, "<main.jl>")
ast_tree = Efus.Parser.try_parse!(parser)

println("--- 2. Abstract Syntax Tree (AST) ---")
# Use the pretty-printer you wrote in `display.jl`
Base.show(stdout, "text/plain", ast_tree)
println()

# 3. Generate Julia code from the AST
generated_expr = Efus.Gen.generate(ast_tree)

println("--- 3. Generated Julia Code (Formatted) ---")
# Use MacroTools.prettify() to get human-readable code
pretty_expr = MacroTools.prettify(generated_expr)
println(pretty_expr)
println()

# You can also use `dump` for a more detailed view of the Expr
# println("--- 4. Dump of Generated Expr ---")
# dump(generated_expr)

