struct EJlBlock <: AbstractStatement
  indent::Int
  code::Expr
end
function eval!(ctx::EfusEvalContext, blk::EJlBlock)::Union{AbstractEfusError,Nothing}
  withmodule(ctx.namespace) do mod
    Core.eval(mod, blk.code)
  end
end
