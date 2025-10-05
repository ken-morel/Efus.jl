affiliate!(c::Statement) = !isnothing(c.parent) ? affiliate!(c.parent, c) : nothing
affiliate!(p::Statement, c::Statement) = push!(p.children, c)

Base.@kwdef struct ComponentCall <: Statement
    parent::Union{Statement, Nothing}
    componentname::Symbol
    arguments::Vector{Tuple{Symbol, Union{Symbol, Nothing}, <:Expression}} = []
    splats::Vector{Symbol} = []
    children::Vector{Statement} = []
end

function show_ast(io::IO, cc::ComponentCall; context::IdDict = IdDict())
    :indent ∉ keys(context) && push!(context, :indent => 0)
    ind = "  "^context[:indent]
    printstyled(io, ind, cc.componentname; STYLE[:compname]...)
    for splat in cc.splats
        printstyled(io, " ", splat; STYLE[:splat]...)
        printstyled(io, "..."; STYLE[:sign]...)
    end
    for (name, sub, val) in cc.arguments
        if !isnothing(sub)
            name = "$name:$sub"
        end
        printstyled(io, " ", name, "="; STYLE[:identifier]...)
        show_ast(io, val)
    end
    context[:indent] += 1
    for child in cc.children
        println()
        show_ast(io, child; context = context)
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
    branches::Vector{IfBranch} = []
end

function show_ast(io::IO, node::If; context = IdDict())
    :indent ∉ keys(context) && push!(context, :indent => 0)
    ind = "  "^context[:indent]
    started = false
    for branch in node.branches
        if !started
            printstyled(io, ind, "if"; STYLE[:keyword]...)
            print(io, " ")
            show_ast(io, branch.condition)
            started = true
        elseif !isnothing(branch.condition)
            printstyled(io, ind, "elseif"; STYLE[:keyword]...)
            print(io, " ")
            show_ast(io, branch.condition)
        else
            printstyled(io, ind, "else"; STYLE[:keyword]...)
        end
        println()
        context[:indent] += 1
        show_ast(io, branch.block; context)
        println()
        context[:indent] -= 1
        printstyled(ind, "end"; STYLE[:keyword]...)
    end
    return
end

Base.@kwdef struct For <: Statement
    parent::Union{Statement, Nothing} = nothing
    elseblock::Union{Nothing, Block} = nothing
    iterator::Ionic
    iterating::Julia
    block::Block
end
