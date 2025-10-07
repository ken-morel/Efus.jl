"""
Definitions and utilities for efus.jl Ast structures.
"""
module Ast

"""
The supertype for all expressions.

See also [`Statement`](@ref)
"""
abstract type Expression end

import ..IonicEfus


"""
    abstract type Statement <: Expression end

Holds a statement.
"""
abstract type Statement <: Expression end


"""
    affiliate!(c::Statement)

Causes the statement to add to it's parents children, if 
it has a parent.
"""
function affiliate! end

"""
    Base.@kwdef struct Block <: Statement

A block is a container for efus statements and 
snippets. Snippets in a block are treated differently
than in a componentcall.
"""
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
