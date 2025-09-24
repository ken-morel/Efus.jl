module Efus

using FunctionWrappers: FunctionWrapper
abstract type EfusError end


include("./component.jl")


include("./Ast.jl")


include("./objects.jl")


include("./reactants.jl")

include("./gen/Gen.jl")

include("./parser/Parser.jl")

include("./macros.jl")
include("./display.jl")

include("./dev.jl")

using .Dev
export codegen_string

using .Parser
export EfusError, EfusParser, try_parse!


end # module Efus
