"""
Definitions and utilities for efus.jl Ast structures.
"""
module Ast

"""
The supertype for all expressions.

See also [`Statement`](@ref)
"""
abstract type Expression end
public Expression

import ..IonicEfus


"""
    abstract type Statement <: Expression end

Holds a statement.
"""
abstract type Statement <: Expression end
public Statement


"""
    affiliate!(c::Statement)

Causes the statement to add to it's parents children, if 
it has a parent.
"""
function affiliate! end
public affiliate!

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
public Block


include("./expressions.jl")
include("./snippet.jl")
include("./statements.jl")
include("./Display.jl")

import .Display: show_ast

public show_ast

affiliate!(p::Block, c::Snippet) = push!(p.snippets, c)

end
