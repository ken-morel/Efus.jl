include("./src/IonicEfus.jl")

using .IonicEfus
using .IonicEfus.Tokens
using .IonicEfus.Parser
using .IonicEfus.Ast

tokenstream = Channel{Tokens.Token}()
exprstream = Channel{Ast.Statement}()

@async open("./test.efus") do io
    tz = Tokens.Tokenizer(tokenstream, Tokens.TextStream(io))
    Tokens.tokenize!(tz)
end
pr = Parser.EfusParser(Parser.TokenStream(tokenstream), exprstream)

errormonitor(@async take!(pr))

println(take!(exprstream))


errormonitor(@async take!(pr))
println(take!(exprstream))


# println.(filter!(!isnothing, tokens))
