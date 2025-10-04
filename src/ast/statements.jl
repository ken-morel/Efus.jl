affiliate!(c::Statement) = !isnothing(c.parent) ? affiliate!(c.parent, c) : nothing
affiliate!(p::Statement, c::Statement) = push!(p.children, c)

Base.@kwdef struct ComponentCall <: Statement
    parent::Union{Statement, Nothing}
    componentname::Symbol
    arguments::Vector{Tuple{Symbol, Union{Symbol, Nothing}, <:Expression}} = []
    splats::Vector{Symbol} = []
    children::Vector{Statement} = []
end

function Base.show(io::IO, cc::ComponentCall; context::IdDict = IdDict([(:indent, 0)]))
    ind = "  "^context[:indent]
    printstyled(io, ind, cc.componentname; color = :blue, bold = true)
    for splat in cc.splats
        print(io, " ", splat, "...")
    end
    for (name, sub, val) in cc.arguments
        if !isnothing(sub)
            name = "$name:$sub"
        end
        print(io, " ", name, "=")
        print(io, val)
    end
    context[:indent] += 1
    for child in cc.children
        println()
        show(io, child; context = context)
    end
    context[:indent] -= 1
    return
end

Base.@kwdef struct IfBranch <: Statement
    condition::Union{Expression, Nothing}
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
