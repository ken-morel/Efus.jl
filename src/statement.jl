export AbstractStatement, AbstractExpression, EvalContext, eval!, ECode

abstract type AbstractExpression <: EObject end
abstract type AbstractStatement <: AbstractExpression end

struct EvalContext
  namespace::AbstractNamespace
  stack::Vector{Tuple{AbstractStatement,Any}}
  EvalContext(namespace::AbstractNamespace, stack::Vector{Tuple{AbstractStatement,Any}}) = new(namespace, stack)
  EvalContext() = new(DictNamespace(), [])
  EvalContext(namespace::AbstractNamespace) = new(namespace, [])
end

struct ECodeBlock
  statements::Vector{AbstractStatement}
end
function eval!(ctx::EvalContext, block::ECodeBlock)::Union{Nothing,EObject}
  for statement ∈ block.statements
    val = eval!(ctx, statement::AbstractStatement)
    iserror(val) && return val
  end
  length(ctx.stack) > 0 ? first(ctx.stack)[2] : nothing
end


struct ECode <: EObject
  block::ECodeBlock
  filename::String
end
function eval!(ctx::EvalContext, code::ECode)::Union{Nothing,EObject}
  eval!(ctx, code.block)
end
function eval!(code::ECode)::Union{Nothing,EObject}
  eval!(EvalContext(), code)
end

include("statements/templatecall.jl")

include("statements/using.jl")

include("statements/ifstatement.jl")

include("statements/comments.jl")

include("statements/errors.jl")
