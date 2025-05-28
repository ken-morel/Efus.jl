struct EIfStatementBranch
  condition::Union{EExpr,Nothing}
  block::ECodeBlock
end
struct EIfStatement <: AbstractStatement
  branches::Vector{EIfStatementBranch}
  indent::Int
  stack::ParserStack
end

function eval!(ctx::EvalContext, statement::EIfStatement)::Union{EObject,Nothing,AbstractError}
  for branch ∈ statement.branches
    test = testbranch(ctx, branch)
    iserror(test) && return test
    if test
      return eval!(ctx, branch.block)
    end
  end
end

function testbranch(ctx::EvalContext, branch::EIfStatementBranch)::Union{Bool,AbstractError}
  branch.condition === nothing || eval(branch.condition, ctx.namespace)
end
