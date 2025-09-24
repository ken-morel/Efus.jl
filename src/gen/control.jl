function generate(node::Ast.IfStatement)
    result = :(nothing)
    for branch in reverse(node.branches)
        condition = if !isnothing(branch.condition)
            generate(branch.condition)
        end
        statement = generate(branch.block)
        println(branch.block)
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
