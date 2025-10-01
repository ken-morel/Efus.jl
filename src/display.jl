module Display

using ..Ast

"""
    show_ast(io, obj; indent = 0, context = IdDict())

Recursively prints an AST node with indentation and colors using `printstyled`.
Tracks visited nodes in `context` to handle circular references.
"""
function show_ast(io::IO, obj::Any; indent = 0, context = IdDict())
    # Default fallback for any type without a specific method
    print(io, " "^indent)
    printstyled(io, summary(obj), color = :light_black)
    return println(io)
end

# --- AbstractValue Methods ---

function show_ast(io::IO, num::Ast.Numeric; indent = 0, context = IdDict())
    print(io, " "^indent)
    printstyled(io, "Numeric", color = :blue)
    printstyled(io, " val=", color = :light_black)
    printstyled(io, num.val, color = :yellow)
    return println(io)
end

function show_ast(io::IO, vec::Ast.Vect; indent = 0, context = IdDict())
    print(io, " "^indent)
    printstyled(io, "Vect", color = :blue)
    println(io)
    for item in vec.items
        show_ast(io, item, indent = indent + 2, context = context)
    end
    return
end

function show_ast(io::IO, ib::Ast.InlineBlock; indent = 0, context = IdDict())
    print(io, " "^indent)
    printstyled(io, "InlineBlock", color = :magenta, bold = true)
    println(io)
    for child in ib.children
        show_ast(io, child, indent = indent + 2, context = context)
    end
    return
end

function show_ast(io::IO, lit::Ast.LiteralValue; indent = 0, context = IdDict())
    print(io, " "^indent)
    printstyled(io, "LiteralValue", color = :blue)
    printstyled(io, " val=", color = :light_black)
    val_color = lit.val isa String ? :green : (lit.val isa Symbol ? :cyan : :yellow)
    printstyled(io, repr(lit.val), color = val_color)
    return println(io)
end

function show_ast(io::IO, expr::Ast.Expression; indent = 0, context = IdDict())
    print(io, " "^indent)
    printstyled(io, "Expression", color = :blue)

    expr_str = string(expr.expr)
    if occursin('\n', expr_str)
        println(io)
        print(io, " "^(indent + 2))
        printstyled(io, "expr:", color = :light_black)
        println(io)
        for line in split(expr_str, '\n')
            print(io, " "^(indent + 4))
            printstyled(io, line, color = :yellow)
            println(io)
        end
    else
        printstyled(io, " expr=", color = :light_black)
        printstyled(io, expr_str, color = :yellow)
        println(io)
    end
end

function show_ast(io::IO, ionic::Ast.Ionic; indent = 0, context = IdDict())
    print(io, " "^indent)
    printstyled(io, "Ionic", color = :blue)

    if ionic.type !== nothing
        printstyled(io, " type=", color = :light_black)
        printstyled(io, ionic.type, color = :cyan)
    end

    expr_str = string(ionic.expr)
    if occursin('\n', expr_str)
        # Drop the final newline from the header line to start the multiline block
        println(io)
        print(io, " "^(indent + 2))
        printstyled(io, "expr:", color = :light_black)
        println(io)
        for line in split(expr_str, '\n')
            print(io, " "^(indent + 4))
            printstyled(io, line, color = :yellow)
            println(io)
        end
    else
        printstyled(io, " expr=", color = :light_black)
        printstyled(io, expr_str, color = :yellow)
        println(io)
    end
end

function show_ast(io::IO, snippet::Ast.Snippet; indent = 0, context = IdDict())
    print(io, " "^indent)
    printstyled(io, "Snippet", color = :magenta, bold = true)
    println(io)
    if !isempty(snippet.params)
        print(io, " "^(indent + 2))
        printstyled(io, "Params:", color = :light_black)
        println(io)
        for (name, type) in snippet.params
            print(io, " "^(indent + 4))
            printstyled(io, name, color = :cyan)
            if type !== nothing
                printstyled(io, "::", color = :light_black)
                printstyled(io, type.expr, color = :yellow)
            end
            println(io)
        end
    end
    return show_ast(io, snippet.content, indent = indent + 2, context = context)
end

# --- AbstractStatement Methods ---

function show_ast(io::IO, block::Ast.Block; indent = 0, context = IdDict())
    if haskey(context, block)
        print(io, " "^indent)
        printstyled(io, "Ast.Block (circular reference)", color = :light_black)
        println(io)
        return
    end
    context[block] = true

    print(io, " "^indent)
    printstyled(io, "Ast.Block", color = :magenta, bold = true)
    println(io)

    for child in block.children
        show_ast(io, child, indent = indent + 2, context = context)
    end
    return
end

function show_ast(io::IO, jb::Ast.JuliaBlock; indent = 0, context = IdDict())
    print(io, " "^indent)
    printstyled(io, "JuliaBlock", color = :magenta, bold = true)
    println(io)
    return show_ast(io, jb.code, indent = indent + 2, context = context)
end

function show_ast(io::IO, statement::Ast.IfStatement; indent = 0, context = IdDict())
    if haskey(context, statement)
        print(io, " "^indent)
        printstyled(io, "Ast.IfStatement (circular reference)", color = :light_black)
        println(io)
        return
    end
    context[statement] = true

    print(io, " "^indent)
    printstyled(io, "Ast.IfStatement", color = :magenta, bold = true)
    println(io)

    for (i, branch) in enumerate(statement.branches)
        print(io, " "^(indent + 2))
        if i == 1
            printstyled(io, "If", color = :cyan)
        else
            if branch.condition === nothing
                printstyled(io, "Else", color = :cyan)
            else
                printstyled(io, "ElseIf", color = :cyan)
            end
        end

        if branch.condition !== nothing
            printstyled(io, " (", color = :cyan)
            printstyled(io, branch.condition.expr, color = :yellow)
            printstyled(io, ")", color = :cyan)
        end
        println(io)

        show_ast(io, branch.block, indent = indent + 4, context = context)
    end
    return
end

function show_ast(io::IO, statement::Ast.ForStatement; indent = 0, context = IdDict())
    if haskey(context, statement)
        print(io, " "^indent)
        printstyled(io, "Ast.ForStatement (circular reference)", color = :light_black)
        println(io)
        return
    end
    context[statement] = true

    print(io, " "^indent)
    printstyled(io, "Ast.ForStatement", color = :magenta, bold = true)
    printstyled(io, " (", color = :cyan)
    printstyled(io, statement.item.expr, color = :yellow)
    printstyled(io, " in ", color = :cyan)
    printstyled(io, statement.iterator.expr, color = :yellow)
    printstyled(io, ")", color = :cyan)
    println(io)

    show_ast(io, statement.block, indent = indent + 4, context = context)

    if statement.elseblock !== nothing
        print(io, " "^(indent + 2))
        printstyled(io, "Else", color = :cyan)
        println(io)
        show_ast(io, statement.elseblock, indent = indent + 4, context = context)
    end
    return
end

function show_ast(io::IO, call::Ast.ComponentCall; indent = 0, context = IdDict())
    if haskey(context, call)
        print(io, " "^indent)
        printstyled(io, "ComponentCall (circular reference)", color = :light_black)
        println(io)
        return
    end
    context[call] = true

    print(io, " "^indent)
    printstyled(io, "ComponentCall", color = :magenta)
    printstyled(io, "(", color = :magenta)
    printstyled(io, ":", call.name, color = :blue)
    printstyled(io, ")", color = :magenta)
    println(io)

    if !isempty(call.arguments)
        print(io, " "^(indent + 2))
        printstyled(io, "Arguments:", color = :light_black)
        println(io)
        for arg in call.arguments
            show_ast(io, arg, indent = indent + 4, context = context)
        end
    end
    if !isempty(call.splats)
        print(io, " "^(indent + 2))
        printstyled(io, "Splats:", color = :light_black)
        println(io)
        for splat in call.splats
            show_ast(io, splat, indent = indent + 4, context = context)
        end
    end
    return if !isempty(call.children)
        print(io, " "^(indent + 2))
        printstyled(io, "Children:", color = :light_black)
        println(io)
        for child in call.children
            show_ast(io, child, indent = indent + 4, context = context)
        end
    end
end

function show_ast(io::IO, arg::Ast.ComponentCallArgument; indent = 0, context = IdDict())
    print(io, " "^indent)
    printstyled(io, "Argument", color = :cyan)
    printstyled(io, " name=:", color = :light_black)
    printstyled(io, arg.name, color = :cyan)
    println(io)

    print(io, " "^(indent + 2))
    printstyled(io, "Value:", color = :light_black)
    println(io)
    return show_ast(io, arg.value, indent = indent + 4, context = context)
end

function show_ast(io::IO, splat::Ast.ComponentCallSplat; indent = 0, context = IdDict())
    print(io, " "^indent)
    printstyled(io, "Splat", color = :cyan)
    printstyled(io, " name=:", color = :light_black)
    printstyled(io, splat.name, color = :cyan)
    return println(io)
end

# --- Base.show Overloads ---

function Base.show(io::IO, ::MIME"text/plain", node::Ast.AbstractExpression)
    return show_ast(IOContext(io, :color => true), node)
end

end # module Display

