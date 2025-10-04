include("./src/IonicEfus.jl")

using .IonicEfus
using .IonicEfus.Tokens
using .IonicEfus.Parser
using .IonicEfus.Ast

tokenstream = Channel{Tokens.Token}()
exprstream = Channel{Ast.Statement}()

errormonitor(
    @async open("./test.efus") do io
        tz = Tokens.Tokenizer(tokenstream, Tokens.TextStream(io))
        Tokens.tokenize!(tz)
    end
)

errormonitor(
    @async let pr = Parser.EfusParser(Parser.TokenStream(tokenstream), exprstream)
        Parser.parse!(pr)
    end
)
parent = take!(exprstream)
for expr in exprstream
    Ast.affiliate!(expr)
end
println(parent)

# println.(filter!(!isnothing, tokens))
