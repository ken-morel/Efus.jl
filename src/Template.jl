struct TemplateParameter
  name::Symbol
  type::DataType
  default::Union{Nothing,EObject}
  required::Bool
  TemplateParameter(pair::Pair{Symbol,DataType})::TemplateParameter =
    new(first(pair), last(pair), nothing, true)
  #TemplateParameter(pair::Pair{Symbol,Pair{DataType,Any}})::TemplateParameter =
  #  new(first(pair), first(last(pair)), last(last(pair)))
end
Base.convert(::Type{TemplateParameter}, pair::Pair)::TemplateParameter = TemplateParameter(pair)
struct Template <: EObject
  name::Symbol
  backend::TemplateBackend
  parameters::Vector{TemplateParameter}
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
mount!(component::Component)::Union{Nothing,AbstractMount} = component.template.backend.mount(component)
unmount!(component::Component) = component.template.backend.unmount(component)
update!(component::Component) = component.template.backend.update(component)
function Base.getindex(comp::Component, key::Symbol)
  val = get(comp.params, key, nothing)
  val === nothing && return missing
  resolve(val.value)
end

Base.push!(parent::Component, child::Component) = push!(parent.children, child)
function (template::Template)(arguments::Vector, namespace::AbstractNamespace, parent::Union{Component,Nothing})::Union{Component,AbstractError}
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
          ParserStack[]
        )
      else
        push!(params, ComponentParameter(parameter, parameter.default))
      end
    else
      argument = popat!(arguments, index)
      params[parameter.name] = ComponentParameter(parameter, argument.value)
    end
  end
  if length(arguments) > 0
    arg = pop!(arguments)
    return TemplateCallError(
      "extra argument $(arg.name) to template $(template.name)",
      template,
      ParserStack[]
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
getstacks(e::TemplateCallError) = e.stacks
function prependstack!(e::TemplateCallError, stack::ParserStack)::TemplateCallError
  pushfirst!(e.stacks, stack)
  e
end
function format(error::TemplateCallError)::String
  stacktrace = join(format.(getstacks(error)) .* "\n")
  message = String(nameof(typeof(error))) * ": " * error.message
  stacktrace * message
end
