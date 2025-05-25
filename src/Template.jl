struct TemplateParameter
  name::Symbol
  type::Type{<:EObject}
  default::Union{Nothing,EObject}
  required::Bool
  TemplateParameter(pair::Pair{Symbol,Type{T}} where T<:EObject)::TemplateParameter =
    new(first(pair), last(pair), nothing, true)
  TemplateParameter(pair::Pair{Symbol,Pair{Type{T},T}} where T<:EObject)::TemplateParameter =
    new(first(pair), first(last(pair)), last(last(pair)))
end
Base.convert(::Type{TemplateParameter}, pair::Pair)::TemplateParameter = TemplateParameter(pair)
struct Template
  name::Symbol
  backend::TemplateBackend
  parameters::Vector{TemplateParameter}
end


struct ComponentParameter
  param::TemplateParameter
  value::EObject
end


struct Component
  template::Template
  params::Dict{Symbol,ComponentParameter}
end

function (template::Template)(arguments::Vector, namespace::AbstractNamespace)::Union{Component,AbstractError}
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
      push!(params, ComponentParameter(parameter, argument.value))
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
  return Component(template, params)
end


struct TemplateCallError <: AbstractError
  message::String
  stacks::String
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
