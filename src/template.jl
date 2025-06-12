export EfusTemplate, Component, getmount, mount!, unmount!, update!, query, queryone

abstract type AbstractTemplate <: EObject end

struct TemplateParameter
  name::Symbol
  type::Union{DataType,Union,UnionAll}
  default::Any
  required::Bool
end
function Base.convert(::Type{TemplateParameter}, pair::Pair)::TemplateParameter
  name = first(pair)
  required::Bool = false
  def = nothing
  name isa Symbol || throw("Typerror, symbol expected as template name")
  sname = String(name)
  if endswith(sname, "!")
    name = Symbol(sname[1:end-1])
    required = true
  end
  spec = last(pair)
  if spec isa Pair
    typespec = first(spec)
    def = last(spec)
    if def !== nothing && !isa(spec, typespec) && typespec <: EMirrorObject
      def = typespec(def)
    end
  else
    def = nothing
    typespec = spec
  end
  TemplateParameter(name, typespec, def, required)
end
Base.convert(::Type{Vector{TemplateParameter}}, items::Vector{Pair}) =
  convert.((TemplateParameter,), items)

struct EfusTemplate <: AbstractTemplate
  name::Symbol
  backend::TemplateBackend
  parameters::Vector{TemplateParameter}
end
struct TemplateModule
  name::Symbol
  templates::Vector{AbstractTemplate}
end
function gettemplate(mod::TemplateModule, templatename::Symbol)::Union{AbstractTemplate,Nothing}
  index = findfirst(tmpl -> tmpl.name == templatename, mod.templates)
  index === nothing && return nothing
  mod.templates[index]
end


struct TemplateCallError <: AbstractEfusError
  message::String
  stacks::Vector{ParserStack}
  template::AbstractTemplate
  TemplateCallError(msg::String, template::AbstractTemplate, stacks::Vector{ParserStack}) = new(msg, stacks, template)
  TemplateCallError(msg::String, template::AbstractTemplate, stack::ParserStack) = new(msg, ParserStack[stack], template)
end
struct ETypeError <: AbstractEfusError
  message::String
  exception::Union{Nothing,Exception}
  stacks::Vector{ParserStack}
  ETypeError(msg::String, stacks::Vector{ParserStack}) = new(msg, nothing, stacks)
  ETypeError(msg::String, stack::ParserStack) = new(msg, nothing, ParserStack[stack])
  ETypeError(msg::String, exception::Exception, stack::ParserStack) = new(
    msg, exception, ParserStack[stack],
  )
end

function Base.display(error::ETypeError)
  println(format(error))
  if !isnothing(error.exception)
    Base.display_error(error.exception)
  end
end
