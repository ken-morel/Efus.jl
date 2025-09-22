include("./src/Efus.jl")

using .Efus

println(@efus "Company foo=(bar and some \"h here)")
