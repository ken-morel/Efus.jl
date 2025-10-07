include("./src/IonicEfus.jl")

using .IonicEfus
using .IonicEfus.Ast
using .IonicEfus.Gen

const FILE = "test.efus"

colors(; args...) = printstyled("HEllo world"; args...)

component = efus"""
MyLabel(children)#Comment
  (println("I am printing $children");)#Comment
end
#Comment
MyLabel #A comment
  if true # A comment
    colors color=:blue
  else # A comment
    colors color=:red bold=true
  end # another one
"""

println(component)
