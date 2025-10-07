function generate(node::Ast.ComponentCall)
    # literally: not all children are ComponentCalls
    kwargs = [Expr(:kw, arg[1], generate(arg[3])) for arg in node.arguments]

    splats = Expr(:parameters, [Expr(:..., splat) for splat in node.splats]...)

    children_exprs = [generate(child) for child in node.children]

    snippets = [Expr(:kw, snippet.name, generate(snippet)) for snippet in node.snippets]

    if !isempty(children_exprs)
        children = Expr(:call, :|>, Expr(:vect, children_exprs...), IonicEfus.cleanchildren)

        children_kw = Expr(:kw, :children, children)
        push!(kwargs, children_kw)
    end
    return Expr(:call, node.componentname, splats, kwargs..., snippets...)
end


function generate(node::Ast.If)
    result = :(nothing)
    for branch in reverse(node.branches)
        condition = if !isnothing(branch.condition)
            generate(branch.condition)
        end
        statement = generate(branch.block)
        result = if !isnothing(condition)
            quote
                if $condition
                    $statement
                else
                    $result
                end
            end
        else
            statement
        end
    end
    return result
end

function generate(node::Ast.For)
    name = gensym("__efus_for__")
    iterating = generate(node.iterating)
    iterator = generate(node.iterator)
    block = generate(node.block)
    return if isnothing(node.elseblock)
        quote
            [$block for $iterating in $iterator]
        end
    else
        quote
            let $name = $iterator
                if isempty($name)
                    $(generate(node.elseblock))
                else
                    [$block for $iterating in $name]
                end
            end
        end
    end
end

function generate(snippet::Ast.Snippet)
    names = Symbol[]
    types = []
    for param in snippet.params
        push!(names, param.name)
        if isnothing(param.type)
            push!(types, Any)
        else
            push!(types, param.type.value)
        end
    end
    namedtupletype = Expr(
        :curly,
        NamedTuple,
        Expr(:tuple, QuoteNode.(names)...),
        Expr(:curly, Tuple, types...),
    )
    exprs = []
    for param in snippet.params
        expr = param.name
        if param.type !== nothing
            expr = Expr(:(::), expr, param.type.value)
        end
        if param.default !== nothing
            expr = Expr(:kw, expr, param.default.value)
        end
        push!(exprs, expr)
    end
    signature = Expr(:parameters, exprs...)
    content = generate(snippet.block)

    snippettype = Expr(:curly, IonicEfus.Snippet, namedtupletype)
    functiondef = Expr(:->, Expr(:tuple, signature), content)
    return Expr(:call, snippettype, functiondef)
end

function generate(param::Ast.SnippetParameter)
    expr = param.name
    if !isnothing(param.type)
        expr = Expr(:(::), expr, param.type.value)
    end
    if !isnothing(param.default)
        expr = Expr(:(=), expr, param.default.value)
    end
    return expr
end


function generate(node::Ast.Block)
    children_exprs = [generate(child) for child in node.children]
    body = Expr(:call, :|>, Expr(:vect, children_exprs...), IonicEfus.cleanchildren)
    return if isempty(node.snippets)
        body
    else
        return Expr(
            :let,
            Expr(:block, [Expr(:(=), snippet.name, generate(snippet)) for snippet in node.snippets]...),
            Expr(:block, body)
        )
    end
end

generate(node::Ast.JuliaBlock) = generate(node.code)
