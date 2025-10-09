include("./src/IonicEfus.jl")

using .IonicEfus
using .IonicEfus.Ast
using .IonicEfus.Gen

using MacroTools

const FILE = "test.efus"

colors(; args...) = printstyled("HEllo world"; args...)

prints = (; what) -> print(what)

hello = "Hello "

a = Reactant("world!")


component = efus"""
prints(what)
  (println(what);)
end

prints what:foo=5
"""

println(component)
