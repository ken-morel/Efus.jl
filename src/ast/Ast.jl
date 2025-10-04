"""
Definitions and utilities for efus.jl Ast structures
"""
module Ast

"""
The supertype for all expressions. Expressions 
"""
abstract type Expression end

abstract type Statement <: Expression end

include("./expressions.jl")
include("./statements.jl")


end
