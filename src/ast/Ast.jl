"""
Definitions and utilities for efus.jl Ast structures
"""
module Ast

"""
The supertype for all expressions. Expressions 
"""
abstract type Expression end

import IonicEfus


abstract type Statement <: Expression end


Base.@kwdef struct Block <: Statement
    children::Vector{Statement} = Statement[]
    snippets::Vector{Statement} = []
end


include("./expressions.jl")
include("./snippet.jl")
include("./statements.jl")
include("./Display.jl")

import .Display: show_ast


affiliate!(p::Block, c::Snippet) = push!(p.snippets, c)
end
