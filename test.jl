include("src/Efus.jl")

using .Efus


#PERF: Place the code in a function to avoid global scope performance issues.
Efus.codegen_string(
    """
    Frame padding=(3, 3)
      Label text=-12.5e6im
      Label banana=[1, 2, 3]
    """, true
) |> println
#TEST: Test several samples
