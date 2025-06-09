abstract type AbstractExpression <: EObject end
abstract type AbstractStatement <: AbstractExpression end

struct EfusEvalContext
  namespace::AbstractNamespace
  stack::Vector{Tuple{AbstractStatement,Any}}
  EfusEvalContext(namespace::AbstractNamespace, stack::Vector{Tuple{AbstractStatement,Any}}) = new(namespace, stack)
  EfusEvalContext() = new(DictNamespace(), [])
  EfusEvalContext(namespace::AbstractNamespace) = new(namespace, [])
end

struct ECodeBlock
  statements::Vector{AbstractStatement}
end
function eval!(ctx::EfusEvalContext, block::ECodeBlock)::Union{Nothing,EObject}
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
function eval!(ctx::EfusEvalContext, code::ECode)::Union{Nothing,EObject}
  eval!(ctx, code.block)
end
function eval!(code::ECode)::Union{Nothing,EObject}
  eval!(EfusEvalContext(), code)
end

include("statements/templatecall.jl")

include("statements/using.jl")

include("statements/ifstatement.jl")

include("statements/comments.jl")

include("statements/errors.jl")
