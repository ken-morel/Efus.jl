"""
IonicEfus.jl is a Julia module that provides the Efus language,
a pug-like declarative syntax for building reactive components.
It features an 'ionic' reactive programming model, allowing
for the creation of dynamic and modular systems that compile
directly to native Julia code.
"""
module IonicEfus

using FunctionWrappers: FunctionWrapper

abstract type EfusError <: Exception end


include("./component.jl")


include("./Ast.jl")
include("./Ionic.jl")


include("./objects.jl")
include("./snippet.jl")

include("./reactants.jl")

include("./gen/Gen.jl")

include("./parser/Parser.jl")

include("./macros.jl")
include("./display.jl")

include("./dev.jl")

include("./tokens/Tokens.jl")


using .Dev
export codegen_string

using .Parser
export EfusError, EfusParser, try_parse!, try_parse, efus_parse

using .Tokens


end # module IonicEfus
