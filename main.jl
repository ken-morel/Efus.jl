include("./src/Efus.jl")

using .Efus

show(
    Core.stdout,
    MIME("text/plain"),
    @efus """
      Label name="ama"
        Okro
        Cment
        Banana args... name=(6)
        Ok c=4
    """
)
