include("./htmlcomponents.jl")

function list(; iter::Vector{T}, body::Snippet{NamedTuple{(:item,), Tuple{T}}}) where {T}
    return [body(item = item) for item in iter]
end

items = ["Tokenizer", "Lexer", "Parser", "Generator", "Compiler", "Optimizer"]

println(
    render(
        efus"""
        list iter=items
          body()
          end
        """
    )
)
