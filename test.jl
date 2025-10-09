include("./src/IonicEfus.jl")

using .IonicEfus
using .IonicEfus.Ast
using .IonicEfus.Gen

const FILE = "test.efus"

colors(; args...) = printstyled("HEllo world"; args...)

prints = (; what) -> print(what)

hello = "Hello "

a = Reactant("world!")


component = efus"""
prints(what)
  (begin
    println(what')
    a' = "Hy"
    println(what')
  end)
end

prints what=(hello * a')::String

# Let's add a syntax error to test error reporting
BrokenComponent text="unclosed string
But multiline"

"""

println(component)
