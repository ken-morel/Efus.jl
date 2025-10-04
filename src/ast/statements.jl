affiliate!(c::Statement) = !isnothing(c.parent) ? affiliate!(c.parent, c) : nothing
affiliate!(p::Statement, c::Statement) = push!(p.children, c)

Base.@kwdef struct Block <: Statement
    children::Vector{Statement} = []
end

Base.@kwdef struct ComponentCall <: Statement
    parent::Union{Statement, Nothing}
    componentname::Symbol
    arguments::Vector{Tuple{Symbol, Union{Symbol, Nothing}, <:Expression}} = []
    splats::Vector{Symbol} = []
    children::Vector{Statement} = []
end

Base.@kwdef struct IfBranch <: Statement
    condition::Union{Julia, Nothing}
    block::Block = Block()
end
affiliate!(p::IfBranch, c::Statement) = affiliate!(p.block, c)

Base.@kwdef struct If <: Statement
    parent::Union{Statement, Nothing} = nothing
    branches::Vector{IfBranch}
end

Base.@kwdef struct For <: Statement
    parent::Union{Statement, Nothing} = nothing
    elseblock::Union{Nothing, Block} = nothing
    iterator::Ionic
    iterating::Julia
    block::Block
end
