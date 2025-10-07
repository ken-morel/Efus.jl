include("./src/IonicEfus.jl")

using .IonicEfus
using .IonicEfus.Tokens
using .IonicEfus.Parser
using .IonicEfus.Ast
using .IonicEfus.Gen
using MacroTools

const FILE = "test.efus"

colors(; args...) = printstyled("HEllo world"; args...)

println(
    Gen.generate(
        IonicEfus.parse_efus(
            """
            snippet(foo)
              Label bar=4
            end
            """
        )
    )
)

#=
banana = efus"""
banana()
  colors color=:blue bold=true
end
"""

banana()
=#
