struct EIfStatementBranch
  condition::Union{EExpr,Nothing}
  block::ECodeBlock
end
struct EIfStatement <: AbstractStatement
  branches::Vector{EIfStatementBranch}
  indent::Int
  stack::ParserStack
end

function eval!(ctx::EfusEvalContext, statement::EIfStatement)::Union{EObject,Nothing,AbstractEfusError}
  for branch ∈ statement.branches
    test = testbranch(ctx, branch)
    iserror(test) && return test
    if test
      return eval!(ctx, branch.block)
    end
  end
end

function testbranch(ctx::EfusEvalContext, branch::EIfStatementBranch)::Union{Bool,AbstractEfusError}
  branch.condition === nothing || Base.eval(branch.condition, ctx.namespace)
end
