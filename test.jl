include("./src/IonicEfus.jl")

using .IonicEfus
using .IonicEfus.Tokens
using .IonicEfus.Parser
using .IonicEfus.Ast
using .IonicEfus.Lexer
buffer = IOBuffer()

@time Lexer.print_lexed(buffer, "Laleb text='a 45 hello-world ?@ama c=45 do snippet for 3&45} end")

@time Lexer.print_lexed("Laleb text='a.45 hello-world ?@ama c=45 do snippet for 3&45} end")


Ast.show_ast(stdout, IonicEfus.parse_efus(read("test.efus", String), "test.efus"))
