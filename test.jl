include("./src/IonicEfus.jl")

using .IonicEfus
using .IonicEfus.Ast
using .IonicEfus.Gen

using MacroTools


colors(; args...) = printstyled("HEllo world"; args...)

prints = (; what) -> print(what)

expr = @macroexpand efus"""
prints what:something=(a, b;c::Int=5) -> () -> 56
"""

print(expr)

print(eval(expr))
