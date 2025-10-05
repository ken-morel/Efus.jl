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
parent = nothing
while true
    try
        ex = take!(exprstream)
        Ast.affiliate!(ex)
        if ex.parent === nothing
            global parent = ex
        end
    catch e
        if !isa(e, InvalidStateException)
            rethrow()
        end
        break
    finally
        Ast.show_ast(stdout, parent)
        println("\n", "-"^20)
    end
end
# println.(filter!(!isnothing, tokens))
