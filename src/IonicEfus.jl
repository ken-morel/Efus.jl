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
include("./snippet.jl")


include("./reactants.jl")


include("./tokens/Tokens.jl")


include("./lexer/Lexer.jl")


include("./ast/Ast.jl")

include("./ionic/Ionic.jl")

include("./parser/Parser.jl")


include("./gen/Gen.jl")

include("./macros.jl")


using .Tokens
using .Parser
using .Ionic
using .Ast

import .Ast: show_ast


include("./parse.jl")

end # module IonicEfus
