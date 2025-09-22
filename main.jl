include("./src/Efus.jl")

using .Efus

@efus "Label class=+34x45px c='b'"
println(@efus "Company banana=\"Hello wodl\" c='b' geo=+12x58px-34")
