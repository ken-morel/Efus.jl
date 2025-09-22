include("./src/Efus.jl")

using .Efus

println(
    @efus """
      Label name="ama"
        Banana
    """
)
