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
            show_ast(io, branch.condition; context)
            started = true
        elseif !isnothing(branch.condition)
            printstyled(io, ind, "elseif"; STYLE[:keyword]...)
            print(io, " ")
            show_ast(io, branch.condition; context)
        else
            printstyled(io, ind, "else"; STYLE[:keyword]...)
        end
        println(io)
        context[:indent] += 1
        show_ast(io, branch.block; context)
        println(io)
        context[:indent] -= 1
    end
    printstyled(io, ind, "end"; STYLE[:keyword]...)
    return
end

Base.@kwdef mutable struct For <: Statement
    parent::Union{Statement, Nothing} = nothing
    elseblock::Union{Nothing, Block} = nothing
    iterator::Expression
    iterating::Expression
    block::Block
end

function show_ast(io::IO, node::For; context = IdDict())
    :indent ∉ keys(context) && push!(context, :indent => 0)
    ind = "  "^context[:indent]
    printstyled(io, ind, "for "; STYLE[:keyword]...)
    show_ast(io, node.iterating; context)
    printstyled(io, " in "; STYLE[:keyword]...)
    show_ast(io, node.iterator; context)
    println(io)
    context[:indent] += 1
    show_ast(io, node.block; context)
    println(io)
    if node.elseblock !== nothing
        printstyled(io, ind, "else\n"; STYLE[:keyword]...)
        show_ast(io, node.elseblock; context)
        println(io)
    end
    context[:indent] -= 1
    printstyled(io, ind, "end"; STYLE[:keyword]...)
    return
end

struct SnippetParameter
    name::Symbol
    type::Union{Some, Nothing}
    default::Union{Some, Nothing}
end
Base.@kwdef struct Snippet <: Statement
    parent::Statement
    name::Symbol
    params::Vector{SnippetParameter}
    block::Block = Block()
end

function takesnippetparameters(expr::Expr)::Vector{SnippetParameter}
    params = SnippetParameter[]
    expr.head !== :tuple && error(
        "Expected a typle of arguments as expr"
    )
    for arg in expr.args
        if arg isa Symbol
            push!(params, SnippetParameter(arg, nothing, nothing))
            continue
        elseif arg isa Expr
            if arg.head === :(::)
                push!(params, SnippetParameter(arg.args[1], Some(arg.args[2]), nothing))
                continue
            elseif arg.head === :(=)
                value = arg.args[2]
                if arg.args[1] isa Expr && arg.args[1].head === :(::)
                    nametype = arg.args[1]
                    push!(params, SnippetParameter(nametype.args[1], nametype.args[2], value))
                    continue
                elseif arg.args[1] isa Symbol
                    push!(params, SnippetParameter(arg.args[1], nothing, Some(arg.args[2])))
                    continue
                end
            end
        end
        error(
            "Invalid snippet parameters, wrong left hand side to equal, in: $(arg)"
        )

    end
    return params
end

function show_ast(io::IO, sn::Snippet; context = IdDict())
    :indent ∉ keys(context) && push!(context, :indent => 0)
    ind = "  "^context[:indent]
    printstyled(io, ind, sn.name; STYLE[:identifier]...)
    printstyled(io, sn.params, "\n"; STYLE[:ionic]...)
    context[:indent] += 1
    show_ast(io, sn.block; context)
    context[:indent] -= 1
    println(io)
    printstyled(io, ind, "end"; STYLE[:keyword]...)
    return
end


function show_ast(io::IO, s::Statement; context = IdDict())
    :indent ∉ keys(context) && push!(context, :indent => 0)
    ind = "  "^context[:indent]
    printstyled(io, ind, s; STYLE[:unknown]...)
    return
end


Base.@kwdef struct ComponentCall <: Statement
    parent::Union{Statement, Nothing}
    componentname::Symbol
    arguments::Vector{Tuple{Symbol, Union{Symbol, Nothing}, <:Expression}} = []
    splats::Vector{Symbol} = []
    children::Vector{Statement} = []
    snippets::Vector{Snippet} = []
end

function show_ast(io::IO, cc::ComponentCall; context::IdDict = IdDict())
    :indent ∉ keys(context) && push!(context, :indent => 0)
    ind = "  "^context[:indent]
    printstyled(io, ind, cc.componentname; STYLE[:compname]...)
    for splat in cc.splats
        printstyled(io, " ", splat; STYLE[:splat]...)
        printstyled(io, "..."; STYLE[:sign]...)
    end
    context[:indent] += 1
    for (name, sub, val) in cc.arguments
        if !isnothing(sub)
            name = "$name:$sub"
        end
        printstyled(io, " ", name, "="; STYLE[:identifier]...)
        show_ast(io, val; context)
    end
    for snippet in cc.snippets
        println(io)
        show_ast(io, snippet; context = context)
    end
    for child in cc.children
        println(io)
        show_ast(io, child; context = context)
    end

    context[:indent] -= 1
    return
end

# A special affiliate for snippets, love this
affiliate!(p::ComponentCall, c::Snippet) = push!(p.snippets, c)

affiliate!(c::Statement) = !isnothing(c.parent) ? affiliate!(c.parent, c) : nothing
affiliate!(p::Statement, c::Statement) = push!(p.children, c)
