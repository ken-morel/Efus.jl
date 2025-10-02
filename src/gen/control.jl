function generate(node::Ast.IfStatement)
    result = :(nothing)
    for branch in reverse(node.branches)
        condition = if !isnothing(branch.condition)
            generate(branch.condition)
        end
        statement = generate(branch.block, true)
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

function generate(node::Ast.ForStatement)
    name = gensym("__efus_for__")
    return if isnothing(node.elseblock)
        quote
            [$(generate(node.block)) for $(generate(node.item)) in $(generate(node.iterator))]
        end
    else
        quote
            let $name = $(generate(node.iterator))
                if isempty($name)
                    $(generate(node.elseblock))
                else
                    [$(generate(node.block)) for $(generate(node.item)) in $name]
                end
            end
        end
    end
end
