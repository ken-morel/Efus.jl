include("./src/tokens/Tokens.jl")

using .Tokens


open("./test.efus") do io
    tz = Tokens.Tokenizer(Tokens.TextStream(io))
    while true
        tk = take!(tz)
        println(tk.type, "(", tk.token, ")")
        tk.type == Tokens.EOF && break
    end
end
