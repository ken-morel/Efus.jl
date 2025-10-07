"""
Definitions and utilities for efus.jl Ast structures
"""
module Ast

"""
The supertype for all expressions. Expressions 
"""
abstract type Expression end

import IonicEfus


function show_ast(io::IO, e::Expression; _...)
    printstyled(io, e; STYLE[:unknown]...)
    return
end

abstract type Statement <: Expression end

const STYLE = Dict{Symbol, Dict{Symbol, Any}}(
    :sign => Dict(:color => :blue),
    :keyword => Dict(:color => :magenta, :bold => true),
    :compname => Dict(:color => :light_magenta),
    :expr => Dict(:color => :green),
    :ionic => Dict(:color => :green, :underline => true),
    :unknown => Dict(:color => :yellow),
    :splat => Dict(:color => :light_blue),
    :identifier => Dict(:color => :light_blue)
)

Base.@kwdef struct Block <: Statement
    children::Vector{Statement} = []
    snippets::Vector{IonicEfus.Snippet} = []
end


function show_ast(io::IO, node::Block; context = IdDict())
    started = false
    for statement in node.children
        started && println()
        started = true
        show_ast(io, statement; context)
    end
    return
end


include("./expressions.jl")
include("./statements.jl")


affiliate!(p::Block, c::Snippet) = push!(p.snippets, c)
end
