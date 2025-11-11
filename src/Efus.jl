"""
IonicEfus.jl is a Julia module that provides the Efus language,
a pug-like declarative syntax for building reactive components that compile
directly to native Julia code.
"""
module Efus

using Reexport

using StructUtils
@reexport using Ionic


abstract type EfusError <: Exception end


include("./component.jl")
include("./snippet.jl")

include("./tokens/Tokens.jl")


include("./lexer/Lexer.jl")


include("./ast/Ast.jl")


include("./parser/Parser.jl")


include("./gen/Gen.jl")
include("./macros.jl")

@reexport using .Tokens, .Parser, .Ionic, .Ast, .Lexer, .Gen

include("./parse.jl")

end
