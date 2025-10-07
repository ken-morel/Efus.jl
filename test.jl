include("./src/IonicEfus.jl")

using .IonicEfus
using .IonicEfus.Ast
using .IonicEfus.Gen

const FILE = "test.efus"

colors(; args...) = printstyled("HEllo world"; args...)

component = efus"""
MyLabel(children
  (println("I am printing $children");)
end

MyLabel
  colors
"""

println(component)
