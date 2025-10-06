include("./src/IonicEfus.jl")

using .IonicEfus
using .IonicEfus.Tokens
using .IonicEfus.Parser
using .IonicEfus.Ast
using .IonicEfus.Lexer

const FILE = "test.efus"
const CODE = read(FILE, String)


@info "Parsing code..."
ast = @time IonicEfus.parse_efus(CODE, FILE)

@info "Showing ast..."
@time Ast.show_ast(stdout, ast)

@info "showing lexed"
@time Lexer.print_lexed(CODE)
