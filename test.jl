include("./src/IonicEfus.jl")

using .IonicEfus
using .IonicEfus.Tokens
using .IonicEfus.Parser
using .IonicEfus.Ast
using .IonicEfus.Gen
using MacroTools

const FILE = "test.efus"

colors(; args...) = printstyled("HEllo world"; args...)


efus"""
colors color=:blue bold=true
"""
