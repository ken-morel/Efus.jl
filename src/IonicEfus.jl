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


include("./reactants.jl")


include("./tokens/Tokens.jl")


include("./ast/Ast.jl")


include("./Ionic.jl")

include("./parser/Parser.jl")


include("./gen/Gen.jl")

include("./macros.jl")

include("./dev.jl")


using .Dev
export codegen_string

using .Parser

using .Tokens


end # module IonicEfus
