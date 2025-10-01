function fussubstitute(orig::Any)
    !isa(orig, Expr) && return orig, []
    expr = copy(orig)
    todo = Set{Expr}([expr])
    dependencies = Symbol[]
    while !isempty(todo)
        current = pop!(todo)
        if current.head == Symbol("'")
            if current.args[1] isa Expr && current.args[1].head == Symbol("'")
                current.args = current.args[1].args
                # double quote escape
                continue
            end
            push!(dependencies, current.args[1])
            current.head = :call
            current.args = [Efus.getvalue, current.args[1]]

        elseif current.head == Symbol("=") && length(current.args) == 2  && current.args[1] isa Expr && current.args[1].head == Symbol("'")
            # it is an assignment to a reactive variable
            reactive_var = current.args[1].args[1]
            value_expr = current.args[2]
            current.head = :call
            current.args = [Efus.setvalue!, reactive_var, value_expr]
        else
            push!.((todo,), filter(x -> x isa Expr, current.args))
        end
    end
    return expr, dependencies
end

function generate(fuss::Ast.Fuss)
    expr, dependencies = fussubstitute(fuss.expr)
    type = something(fussubstitute(fuss.type)[1], Any)

    return if isempty(dependencies)
        Expr(:(::), expr, type)
    else
        quote
            $(Efus.Reactor){$type}(
                () -> $expr,
                nothing,
                $(Expr(:vect, dependencies...))
            )
        end
    end
end
