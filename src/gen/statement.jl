"""
    generate(node::Ast.ComponentCall)

Generates the function call for a componentcall
The generated is a simple function call, with
it's parameters and direct snippets as arguments
and a special keyword argument `children` which
is passed only if the component had children(which
were not snippets) and is the children expression 
is wrapped in [`Efus.cleanchildren`](@ref)
to make sure children is of type `Vector{Component}`
"""
function generate(node::Ast.ComponentCall)
    # literally: not all children are ComponentCalls

    args = Dict{Symbol,Ast.Expression}()
    dictargs = Dict{Symbol,Dict{Symbol,Ast.Expression}}()

    for (argname, argsub, argvalue) in node.arguments
        if isnothing(argsub)
            push!(args, argname => argvalue)
        else
            argname ∉ keys(dictargs) &&
                push!(dictargs, argname => Dict{Symbol,Ast.Expression}())
            dictargs[argname][argsub] = argvalue
        end
    end
    common = intersect(keys(args), keys(dictargs))
    !isempty(common) && throw(
        CodeGenerationError(
            "Could not generate component call. Call for component $(node.componentname)" *
            " has arguments $common which were both regular arguments and dict(with :)" *
            " arguments",
        ),
    )
    kwargs = [Expr(:kw, key, generate(value)) for (key, value) in args]
    push!(
        kwargs,
        [
            Expr(
                :kw,
                key,
                Expr(
                    :call,
                    :Dict,
                    [
                        Expr(:call, :(=>), QuoteNode(subkey), generate(value)) for
                        (subkey, value) in subdict
                    ]...,
                ),
            ) for (key, subdict) in dictargs
        ]...,
    )

    splats = Expr(:parameters, [Expr(:..., splat) for splat in node.splats]...)

    children_exprs = [generate(child) for child in node.children]

    snippets = [Expr(:kw, snippet.name, generate(snippet)) for snippet in node.snippets]

    if !isempty(children_exprs)
        children = Expr(:call, :|>, Expr(:vect, children_exprs...), Efus.cleanchildren)

        children_kw = Expr(:kw, :children, children)
        push!(kwargs, children_kw)
    end
    return Expr(:call, node.componentname, splats, kwargs..., snippets...)
end


"""
    generate(node::Ast.If)

Generates an if statement and
other if's inside the else block(
in case of elseif). If it has, an else block is
also generated.
"""
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

"""
    generate(node::Ast.For)

Generates a list comprehension, like
`[\$block for \$iterating in \$iterator]`
but if the for loop has an else block, it
evaluates the iterator and assigns a
nonconclicting name in a let block, containing
an if statement returning from a comprehension or
the else block depending on the return of
`isempty` on the iterable.
"""
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

"""
    generate(snippet::Ast.Snippet)

Generate a [`Efus.Snippet`](@ref) definition
and construct it's type from the types of the
ast snippet, and an anonymous function.

# Example
```julia
header(foo::Bar = 5, bar = 5, a::C)
  <content>
end
------
Snippet{
  NamedTuple{
    (:foo, :bar, :a),
    Tuple{Bar, Any, C}
  }
}((foo::Bar = 5, bar = 5, a::C) -> <content>)
```
"""
function generate(snippet::Ast.Snippet)
    params = generate(snippet.params)

    content = generate(snippet.block)

    return Expr(:call, Efus.Snippet, Expr(:->, params, content))
end

"""
    generate(node::Ast.Block)

Generattes the content of the block as
a vector definition, which is passed to
[`Efus.cleanchildren`](@ref).
Contrarily to component calls, here snippets
are grouped in a let call wrapping the rest
of the content, so they can be used as
functions anywhere in the block.
"""
function generate(node::Ast.Block)
    children_exprs = [generate(child) for child in node.children]
    body = Expr(:call, :|>, Expr(:vect, children_exprs...), Efus.cleanchildren)
    return if isempty(node.snippets)
        body
    else
        return Expr(
            :let,
            Expr(
                :block,
                [
                    Expr(:(=), snippet.name, generate(snippet)) for snippet in node.snippets
                ]...,
            ),
            Expr(:block, body),
        )
    end
end

"""
    generate(node::Ast.JuliaBlock)

Generates a block of julia code,
from the contained [`Ast.Julia`](@ref).
"""
generate(node::Ast.JuliaBlock) = generate(node.code)
