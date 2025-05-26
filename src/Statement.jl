abstract type AbstractExpression <: EObject end
abstract type AbstractStatement <: AbstractExpression end

struct EvalContext
  namespace::AbstractNamespace
  stack::Vector{Tuple{AbstractStatement,Any}}
end

struct TemplateCallArgument
  name::Symbol
  value::EObject
end

struct TemplateCall <: AbstractStatement
  templatename::Symbol
  objectalias::Union{Symbol,Nothing}
  arguments::Vector{TemplateCallArgument}
  indent::Int
  stack::ParserStack
end
function eval!(ctx::EvalContext, call::TemplateCall)::Union{AbstractError,EObject}
  template = gettemplate(ctx.namespace, call.templatename)
  if template === nothing
    return NameError("Template named $(call.templatename) not found in namespace", call.templatename, ctx.namespace, call.stack)
  end
  while length(ctx.stack) > 0 && last(ctx.stack)[1].indent >= call.indent
    pop!(ctx.stack)
  end
  parent = length(ctx.stack) > 0 ? last(ctx.stack)[2] : nothing
  comp = template(call.arguments, ctx.namespace, parent)
  parent === nothing || push!(parent, comp)
  push!(ctx.stack, (call, comp))
  comp
end

struct ECode <: EObject
  statements::Vector{AbstractStatement}
  filename::String
end
function eval!(ctx::EvalContext, code::ECode)::Union{Nothing,EObject}
  for statement ∈ code.statements
    val = eval!(ctx, statement::AbstractStatement)
    iserror(val) && return val
  end
  length(ctx.stack) > 0 ? first(ctx.stack)[2] : nothing
end



struct NameError <: AbstractError
  message::String
  stacks::Vector{ParserStack}
  name::Symbol
  namespace::AbstractNamespace #AbstractNamespace
  NameError(msg::String, name::Symbol, namespace::AbstractNamespace, stacks::Vector{ParserStack}) = new(msg, stacks, name, namespace)
  NameError(msg::String, name::Symbol, namespace::AbstractNamespace, stack::ParserStack) = new(msg, ParserStack[stack], name, namespace)
end
getstacks(e::NameError) = e.stacks
function prependstack!(e::NameError, stack::ParserStack)::NameError
  pushfirst!(e.stacks, stack)
  e
end
function format(error::NameError)::String
  stacktrace = join(format.(getstacks(error)) .* "\n")
  message = String(nameof(typeof(error))) * ": " * error.message
  stacktrace * message
end
