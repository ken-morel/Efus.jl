module Display

import ..Ast

export show_ast

"""
    # summary
    show_ast(io::IO, node::Ast.Expression; context = IdDict())

Shows a colorful indented display of the ast structure
to the specified io, using printstyled and styles 
specified in [`STYLE`](@ref.
"""
function show_ast end

show_ast(expr::Ast.Expression) = show_ast(stdout, expr)


"""
    const STYLE::Dict{Symbol, Dict{Symbol, Any}}

The ast displaying styles used with printstyled. You
can update this dictionary keys to change how 
they display.

# Examples

```julia
IonicEfus.Ast.Display.STYLE[:sign] = Dict(:color => :blue, :bold = true)
```
"""
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

public STYLE

function show_ast(io::IO, node::Ast.Block; context = IdDict())
    started = false
    for statement in node.children
        started && println()
        started = true
        show_ast(io, statement; context)
    end
    return
end


function show_ast(io::IO, e::Ast.Expression; _...)
    printstyled(io, e; STYLE[:unknown]...)
    return
end
function show_ast(io::IO, i::Ast.Reactor; _...)
    printstyled(io, repr(i.expr); STYLE[:ionic]...)
    if !isnothing(i.type)
        printstyled(io, "::"; STYLE[:sign]...)
        printstyled(io, repr(i.type); STYLE[:ionic]...)
    end
    return
end
function show_ast(io::IO, j::Ast.Julia; _...)
    return printstyled(io, repr(j.expr); STYLE[:expr]...)
end


function show_ast(io::IO, v::Ast.Vect; context = IdDict())
    :indent ∉ keys(context) && push!(context, :indent => 0)
    ind = "  "^context[:indent]
    printstyled(io, "[\n"; STYLE[:sign]...)
    context[:indent] += 1
    for item in v.items
        print(ind * "  ")
        show_ast(io, item; context = context)
        printstyled(io, ",\n"; STYLE[:sign]...)
    end
    context[:indent] -= 1
    printstyled(io, ind, "]"; STYLE[:sign]...)
    return
end
function show_ast(io::IO, node::Ast.If; context = IdDict())
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
function show_ast(io::IO, node::Ast.For; context = IdDict())
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

function show_ast(io::IO, cc::Ast.ComponentCall; context::IdDict = IdDict())
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
function show_ast(io::IO, sn::Ast.Snippet; context = IdDict())
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


function show_ast(io::IO, s::Ast.Statement; context = IdDict())
    :indent ∉ keys(context) && push!(context, :indent => 0)
    ind = "  "^context[:indent]
    printstyled(io, ind, s; STYLE[:unknown]...)
    return
end


function show_ast(io::IO, b::Ast.JuliaBlock; context = IdDict())
    :indent ∉ keys(context) && push!(context, :indent => 0)
    ind = "  "^context[:indent]

    io = IOBuffer()
    show_ast(io, b.code)
    code = String(take!(io))
    lines = split(code, '\n')

    textio = IOBuffer()
    for line in lines
        write(textio, ind, line, "\n")
    end
    text = String(take!(textio))
    printstyled(io, text; STYLE[:ionic]...)
    return

end

end
