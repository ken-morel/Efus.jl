include("src/Efus.jl")

using .Efus

Efus.codegen_string(
    """
    Frame padding=3x3
      Label text="Hello world" args...
      Button
    """
) |> println
