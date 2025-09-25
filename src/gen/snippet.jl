function generate(snippet::Ast.Snippet)
    names = keys(snippet.params)
    types = map(values(snippet.params)) do p
        if isnothing(p)
            :Any
        else
            generate(p)
        end
    end
    params = map(zip(names, types)) do (name, type)
        Expr(:(::), name, type)
    end
    fn = Expr(:->, Expr(:tuple, params...), Expr(:block, generate(snippet.content, true)))
    typeassert = Expr(:curly, Efus.Snippet, Expr(:curly, :Tuple, types...))
    return Expr(:call, typeassert, fn)
end
