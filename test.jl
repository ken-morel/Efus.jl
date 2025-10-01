include("src/Efus.jl")

using .Efus


#PERF: Place the code in a function to avoid global scope performance issues.
Efus.codegen_string(
    """
    Label padding=[
      (d' = c' * ama';d' / 4),
      do c::Int
        Button text=ama
      end,
      (ama', 4)
    ]
    """, true
) |> println
#TEST: Test several samples
