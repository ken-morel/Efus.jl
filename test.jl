include("./src/IonicEfus.jl")

using .IonicEfus
using .IonicEfus.Tokens
using .IonicEfus.Parser
using .IonicEfus.Ast


Ast.show_ast(stdout, IonicEfus.parse_efus("Hello ama=3"))
