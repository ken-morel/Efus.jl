"""
Definitions and utilities for efus.jl Ast structures
"""
module Ast

"""
The supertype for all expressions. Expressions 
"""
abstract type Expression end

abstract type Statement <: Expression end

const STYLE = Dict{Symbol, Dict{Symbol, Any}}(
    :sign => Dict(:color => :blue),
    :keyword => Dict(:color => :magenta, :bold => true),
    :compname => Dict(:color => :light_magenta),
    :expr => Dict(:color => :green),
    :ionic => Dict(:color => :green, :underline => true),
    :unknown => Dict(:color => :gray),
    :splat => Dict(:color => :light_blue),
    :identifier => Dict(:color => :light_blue)
)

Base.@kwdef struct Block <: Statement
    children::Vector{Statement} = []
end

function show_ast(io::IO, node::Block; context = IdDict())
    :indent ∉ keys(context) && push!(context, :indent => 0)
    ind = "  "^context[:indent]
    printstyled(ind, "begin"; color = :magenta, bold = true)
    println()
    context[:indent] += 1
    for statement in node.children
        show_ast(io, statement; context)
        println()
    end
    context[:indent] -= 1
    printstyled(ind, "end"; color = :magenta, bold = true)
    return
end


include("./expressions.jl")
include("./statements.jl")


end
