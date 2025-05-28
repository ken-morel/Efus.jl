struct EUsing <: AbstractStatement
  mod::Symbol
  imports::Union{Nothing,Vector{Symbol}}
  stack::ParserStack
  indent::Int
end
function eval!(ctx::EvalContext, eusing::EUsing)::Union{AbstractError,Nothing}
  imp = importmodule!(ctx.namespace, eusing.mod, eusing.imports)
  iserror(imp) && prependstack!(imp, eusing.stack)
  imp
end
