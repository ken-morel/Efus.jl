module Efus

using FunctionWrappers: FunctionWrapper

abstract type EfusError end


include("./reactants.jl")


include("./Ast.jl")

include("./objects.jl")

include("./parser/Parser.jl")

include("./macros.jl")


end # module Efus
