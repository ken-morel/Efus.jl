"""
    module Ionic

Stores utility functions for processing ionic expressions.
"""
module Ionic

export transcribe

using ..IonicEfus: getvalue, setvalue!

"""
    function transcribe(orig)::Tuple{Any, Vector}

Translate an ionic expression by replacing all occurrences of 
`var'` with `IonicEfus.getvalue(var)` and all assignments to 
`var'` = value` with `IonicEfus.setvalue!(var, value)` and 
returning the new code and all dependencies.
Where a double '' in gets translated to a single ' and ignored.
"""
function transcribe(orig)::Tuple{Any, Vector}
    !isa(orig, Expr) && return orig, []
    expr = copy(orig)
    todo = Vector{Expr}([expr])
    dependencies = []
    while !isempty(todo)
        current = pop!(todo)
        if current.head == Symbol("'")
            if current.args[1] isa Expr && current.args[1].head == Symbol("'")
                current.args = current.args[1].args
                # double quote escape
                # check inside quote itself
                current.args[1] isa Expr && push!(todo, current.args[1])
                continue
            end
            push!(dependencies, current.args[1])
            current.head = :call
            current.args = [getvalue, current.args[1]]
            current.args[1] isa Expr && push!(todo, current.args[1])
        elseif current.head == Symbol("=") && length(current.args) == 2  && current.args[1] isa Expr && current.args[1].head == Symbol("'")
            # it is an assignment to a reactive variable
            reactive_var = current.args[1].args[1]
            value_expr = current.args[2]
            current.head = :call
            current.args = [setvalue!, reactive_var, value_expr]

            reactive_var isa Expr && push!(todo, reactive_var)
            value_expr isa Expr && push!(todo, value_expr)
        else
            push!(todo, filter(x -> x isa Expr, current.args)...)
        end
    end
    return expr, dependencies
end

end
