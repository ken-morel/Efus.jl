struct EIfStatementBranch
  condition::Union{EExpr,Nothing}
  block::Vector{AbstractStatement}
end
struct EIfStatement <: AbstractStatement
  branches::Vector{EIfStatementBranch}
  indent::Int
  stack::ParserStack
end

function eval!(ctx::EvalContext, statement::EIfStatement)::Union{EObject,Nothing}
end
