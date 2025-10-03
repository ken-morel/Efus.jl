include("./src/tokens/Tokens.jl")

using .Tokens


open("./test.efus") do io
    tz = Tokens.Tokenizer(
        Tokens.TextStream(
            """
            Frame label=ama'
              Lalel text=ama
                    """
        )
    )
    tk = take!(tz)
    while tk.type != Tokens.EOF
        tk = take!(tz)
        println(tk.type, "(", tk.token, ")")
    end
end
