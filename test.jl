include("src/Efus.jl")

using .Efus

Efus.codegen_string(
    """
    Frame padding=3x3
      Scale size=20x20 value=4 val=(hello' * "friend") args...
    """, true
) |> println
