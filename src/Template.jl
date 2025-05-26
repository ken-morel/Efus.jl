struct TemplateParameter
  name::Symbol
  type::DataType
  default::Union{Nothing,EObject}
  required::Bool
  TemplateParameter(pair::Pair{Symbol,DataType})::TemplateParameter =
    new(first(pair), last(pair), nothing, true)
  TemplateParameter(pair::Pair{Symbol,<:Pair{DataType,<:EObject}})::TemplateParameter =
    new(first(pair), first(last(pair)), last(last(pair)))
end
Base.convert(::Type{TemplateParameter}, pair::Pair)::TemplateParameter = TemplateParameter(pair)
struct Template <: EObject
  name::Symbol
  backend::TemplateBackend
  parameters::Vector{TemplateParameter}
end
struct TemplateModule
  name::Symbol
  templates::Vector{Template}
end
function gettemplate(mod::TemplateModule, templatename::Symbol)::Union{Template,Nothing}
  index = findfirst(tmpl -> tmpl.name == templatename, mod.templates)
  index === nothing && return nothing
  mod.templates[index]
end


struct ComponentParameter
  param::TemplateParameter
  value::EObject
end

struct Component <: EObject
  template::Template
  params::Dict{Symbol,ComponentParameter}
  namespace::AbstractNamespace
  parent::Union{Component,Nothing}
  children::Vector{Component}
  mount::Union{Nothing,AbstractMount}
end

mount!(_::TemplateBackend, _::Component) = throw("Mounting not supported by backend")
unmount!(_::TemplateBackend, _::Component) = throw("Unmounting not supported by backend")
update!(_::TemplateBackend, _::Component) = throw("Updating not supported by backend")
mount!(component::Component)::Union{Nothing,AbstractMount} = mount!(component.template.backend, component)
unmount!(component::Component) = unmount!(component.template.backend, component)
update!(component::Component) = update!(component.template.backend, component)
function Base.getindex(comp::Component, key::Symbol)
  val = get(comp.params, key, nothing)
  val === nothing && return missing
  resolve(val.value)
end

Base.push!(parent::Component, child::Component) = push!(parent.children, child)
function (template::Template)(arguments::Vector, namespace::AbstractNamespace, parent::Union{Component,Nothing}, stack::Union{ParserStack,Nothing}=nothing)::Union{Component,AbstractError}
  params::Dict{Symbol,ComponentParameter} = Dict()
  arguments = arguments[:]
  for parameter ∈ template.parameters
    index = findfirst(arguments) do arg
      arg.name == parameter.name
    end
    if index === nothing
      if parameter.required
        return TemplateCallError(
          "Missing value for required parameter $(parameter.name) to template $(template.name)",
          template,
          stack === nothing ? ParserStack[] : ParserStack[stack]
        )
      else
        push!(params, ComponentParameter(parameter, parameter.default))
      end
    else
      argument = popat!(arguments, index)
      if !isa(argument.value, parameter.type)
        return ETypeError("argument of type $(typeof(argument.value)) does not match spec of parameter $(parameter.name)::$(parameter.type) of template $(template.name)", argument.stack)
      end
      params[parameter.name] = ComponentParameter(parameter, argument.value)
    end
  end
  if length(arguments) > 0
    arg = pop!(arguments)
    return TemplateCallError(
      "extra argument $(arg.name) to template $(template.name)",
      template,
      ParserStack[arg.stack]
    )
  end
  return Component(template, params, namespace, parent, Component[], nothing)
end


struct TemplateCallError <: AbstractError
  message::String
  stacks::Vector{ParserStack}
  template::Template
  TemplateCallError(msg::String, template::Template, stacks::Vector{ParserStack}) = new(msg, stacks, template)
  TemplateCallError(msg::String, template::Template, stack::ParserStack) = new(msg, ParserStack[stack], template)
end
struct ETypeError <: AbstractError
  message::String
  stacks::Vector{ParserStack}
  ETypeError(msg::String, stacks::Vector{ParserStack}) = new(msg, stacks)
  ETypeError(msg::String, stack::ParserStack) = new(msg, ParserStack[stack])
end
