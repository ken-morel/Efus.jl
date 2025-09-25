include("src/Efus.jl")

using .Efus

Efus.codegen_string(
    """
    Frame padding=3x3
      Scale size=20x20 value=4 val=(hello' * "friend") args...
      if banana == 4
        Button lbl=true
        for label in [1, 2, 3]
          FoorContent
        else
          ForElse
        end
      else
        Text ama=false
      end
    """, true
) |> println
