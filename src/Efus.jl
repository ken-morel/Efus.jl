module Efus

using FunctionWrappers: FunctionWrapper

abstract type EfusError end


include("./reactants.jl")

include("./component.jl")


include("./Ast.jl")


include("./objects.jl")


include("./gen/Gen.jl")

include("./parser/Parser.jl")

include("./macros.jl")
include("./display.jl")


end # module Efus
