struct EForStatement <: AbstractStatement
  indent::Int
  alias::Symbol
  iterable::EExpr
  block::ECodeBlock
  stack::ParserStack
end

function eval!(ctx::EfusEvalContext, statement::EForStatement)::Union{EObject,Nothing,AbstractEfusError}
  iterable = Base.eval(statement.iterable, ctx.namespace)
  iserror(iterable) && return iterable
  for item ∈ iterable
    ctx.namespace[statement.alias] = item
    while length(ctx.stack) > 0 && last(ctx.stack)[1].indent >= statement.indent
      pop!(ctx.stack)
    end
    value = eval!(ctx, statement.block)
    iserror(value) && return value
  end
end
