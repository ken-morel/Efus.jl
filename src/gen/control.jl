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

# just to see what it will look like, and for debugging :-)
function generate(node::Ast.ForStatement)
    name = gensym("efus")
    return quote
        let $name = $(generate(node.iterator))
            if isempty($name)
                $(generate(node.elseblock))
            else
                [$(generate(node.block)) for $(generate(node.item)) in $name]
            end
        end
    end
end
