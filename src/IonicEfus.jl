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


include("./lexer/Lexer.jl")


include("./ast/Ast.jl")


include("./Ionic.jl")

include("./parser/Parser.jl")


include("./gen/Gen.jl")

include("./macros.jl")


include("./snippet.jl")


using .Parser

using .Tokens

include("./parse.jl")

end # module IonicEfus
