module Display

using ..Ast

"""
    show_ast(io, obj; indent = 0, context = IdDict())

Recursively prints an AST node with indentation and colors using `printstyled`.
Tracks visited nodes in `context` to handle circular references.
"""
function show_ast(io::IO, obj::Any; indent = 0, context = IdDict())
    # Default fallback for any type without a specific method
    print(io, " " ^ indent)
    printstyled(io, summary(obj), color=:light_black)
    println(io)
end

function show_ast(io::IO, block::Ast.Block; indent = 0, context = IdDict())
    if haskey(context, block)
        print(io, " " ^ indent)
        printstyled(io, "Ast.Block (circular reference)", color=:light_black)
        println(io)
        return
    end
    context[block] = true
    
    print(io, " " ^ indent)
    printstyled(io, "Ast.Block", color=:magenta, bold=true)
    println(io)

    for child in block.children
        show_ast(io, child, indent = indent + 2, context = context)
    end
end

function show_ast(io::IO, call::Ast.ComponentCall; indent = 0, context = IdDict())
    if haskey(context, call)
        print(io, " " ^ indent)
        printstyled(io, "ComponentCall (circular reference)", color=:light_black)
        println(io)
        return
    end
    context[call] = true

    print(io, " " ^ indent)
    printstyled(io, "ComponentCall", color=:magenta)
    printstyled(io, "(", color=:magenta)
    printstyled(io, ":", call.name, color=:blue)
    printstyled(io, ")", color=:magenta)
    println(io)

    if !isempty(call.arguments)
        print(io, " " ^ (indent + 2))
        printstyled(io, "Arguments:", color=:light_black)
        println(io)
        for arg in call.arguments
            show_ast(io, arg, indent = indent + 4, context = context)
        end
    end
    if !isempty(call.splats)
        print(io, " " ^ (indent + 2))
        printstyled(io, "Splats:", color=:light_black)
        println(io)
        for splat in call.splats
            show_ast(io, splat, indent = indent + 4, context = context)
        end
    end
    if !isempty(call.children)
        print(io, " " ^ (indent + 2))
        printstyled(io, "Children:", color=:light_black)
        println(io)
        for child in call.children
            show_ast(io, child, indent = indent + 4, context = context)
        end
    end
end

function show_ast(io::IO, arg::Ast.ComponentCallArgument; indent = 0, context = IdDict())
    print(io, " " ^ indent)
    printstyled(io, "Argument(", color=:cyan)
    printstyled(io, ":", arg.name, color=:cyan)
    printstyled(io, ", value=", color=:cyan)

    value_obj = arg.value
    if value_obj isa Ast.LiteralValue
        val = value_obj.val
        val_color = val isa String ? :green : :yellow
        printstyled(io, repr(val), color=val_color)
    elseif value_obj isa Ast.Expression
        printstyled(io, value_obj.expr, color=:cyan)
    else
        printstyled(io, summary(value_obj), color=:light_black)
    end
    
    printstyled(io, ")", color=:cyan)
    println(io)
end

function show_ast(io::IO, splat::Ast.ComponentCallSplat; indent = 0, context = IdDict())
    print(io, " " ^ indent)
    printstyled(io, "Splat(", color=:cyan)
    printstyled(io, ":", splat.name, color=:cyan)
    printstyled(io, ")", color=:cyan)
    println(io)
end

# Overload Base.show to use our pretty-printer.
function Base.show(io::IO, ::MIME"text/plain", block::Ast.Block)
    show_ast(IOContext(io, :color => true), block)
end

function Base.show(io::IO, ::MIME"text/plain", statement::Ast.AbstractStatement)
    show_ast(IOContext(io, :color => true), statement)
end

end # module Display
