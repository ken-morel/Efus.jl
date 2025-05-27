export AbstractStatement, AbstractExpression, EvalContext, eval!, ECode

abstract type AbstractExpression <: EObject end
abstract type AbstractStatement <: AbstractExpression end

struct EvalContext
  namespace::AbstractNamespace
  stack::Vector{Tuple{AbstractStatement,Any}}
  EvalContext(namespace::AbstractNamespace, stack::Vector{Tuple{AbstractStatement,Any}}) = new(namespace, stack)
  EvalContext() = new(Namespace(), [])
  EvalContext(namespace::AbstractNamespace) = new(namespace, [])
end

struct TemplateCallArgument
  name::Symbol
  value::EObject
  stack::ParserStack
end

struct TemplateCall <: AbstractStatement
  templatemod::Union{Symbol,Nothing}
  templatename::Symbol
  objectalias::Union{Symbol,Nothing}
  arguments::Vector{TemplateCallArgument}
  indent::Int
  stack::ParserStack
end
function eval!(ctx::EvalContext, call::TemplateCall)::Union{AbstractError,EObject}
  template = if call.templatemod === nothing
    gettemplate(ctx.namespace, call.templatename)
  else
    tmpl = gettemplate(call.templatemod, call.templatename)
    tmpl === nothing && return NameError("Template named $(call.templatename) not found in module $(call.templatemod)", call.templatename, ctx.namespace, call.stack)
    tmpl
  end
  if template === nothing
    return NameError("Template named $(call.templatename) not found in namespace", call.templatename, ctx.namespace, call.stack)
  end
  while length(ctx.stack) > 0 && last(ctx.stack)[1].indent >= call.indent
    pop!(ctx.stack)
  end
  parent = length(ctx.stack) > 0 ? last(ctx.stack)[2] : nothing
  comp = template(call.arguments, ctx.namespace, parent, call.stack)
  iserror(comp) && return comp
  push!(ctx.stack, (call, comp))
  comp
end


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
function eval!(code::ECode)::Union{Nothing,EObject}
  eval!(EvalContext(), code)
end



struct NameError <: AbstractError
  message::String
  stacks::Vector{ParserStack}
  name::Symbol
  namespace::AbstractNamespace #AbstractNamespace
  NameError(msg::String, name::Symbol, namespace::AbstractNamespace, stacks::Vector{ParserStack}) = new(msg, stacks, name, namespace)
  NameError(msg::String, name::Symbol, namespace::AbstractNamespace, stack::ParserStack) = new(msg, ParserStack[stack], name, namespace)
end

struct ImportError <: AbstractError
  message::String
  stacks::Vector{ParserStack}
  ImportError(msg::String, stacks::Vector{ParserStack}) = new(msg, stacks)
  ImportError(msg::String, stack::ParserStack) = new(msg, ParserStack[stack])
end

