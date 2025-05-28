abstract type AbstractComponent <: EObject end
function master(comp::AbstractComponent)
  while parent(comp) !== nothing
    comp = inlet(parent(comp))
  end
  comp
end
function Base.getindex(comp::AbstractComponent, key::Symbol)
  get(getargs(comp), key, nothing)
end
function Base.setindex!(comp::AbstractComponent, value, key::Symbol)
  param = get(comp.params, key, nothing)
  comp.params[key] = ComponentParameter(param !== nothing ? param.param : nothing, key, value, true, nothing)
  comp.dirty = true
end

struct ComponentParameter
  param::Union{TemplateParameter,Nothing}
  name::Symbol
  value::Any
  evaluated::Bool
  stack::Union{ParserStack,Nothing}
end

mutable struct Component <: AbstractComponent
  template::Template
  params::Dict{Symbol,ComponentParameter}
  args::Dict{Symbol,Any}
  namespace::AbstractNamespace
  parent::Union{AbstractComponent,Nothing}
  children::Vector{AbstractComponent}
  mount::Union{Nothing,AbstractMount}
  dirty::Bool
  Component(template::AbstractTemplate,
    params::Dict{Symbol,ComponentParameter},
    args::Dict{Symbol,Any},
    namespace::AbstractNamespace,
    parent::Union{AbstractComponent,Nothing},
  ) = new(template, params, args, namespace, parent, AbstractComponent[], nothing, false)
end
getargs(comp::AbstractComponent) = comp.args
getparams(comp::AbstractComponent) = comp.params
isdirty(comp::AbstractComponent) = comp.dirty
dirty!(comp::AbstractComponent, dirt::Bool) = (comp.dirty = dirt)
getmount(comp::Component) = comp.mount
mount!(_::TemplateBackend, _::Component) = throw("Mounting not supported by backend")
unmount!(_::TemplateBackend, _::Component) = throw("Unmounting not supported by backend")
update!(_::TemplateBackend, _::Component) = throw("Updating not supported by backend")
mount!(component::Component)::Union{Nothing,AbstractMount} = mount!(component.template.backend, component)
unmount!(component::Component) = unmount!(component.template.backend, component)
update!(component::Component) = update!(component.template.backend, component)
parent(comp::Component) = comp.parent
inlet(comp::Component)::Component = comp
outlet(comp::Component)::Component = comp



Base.push!(parent::AbstractComponent, child::AbstractComponent) = push!(parent.children, child)
function matchparams(template::AbstractTemplate, arguments::Vector)::Union{AbstractError,Dict{Symbol,ComponentParameter}}
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
        params[parameter.name] = ComponentParameter(parameter, parameter.name, parameter.default, true, nothing)
      end
    else
      argument = popat!(arguments, index)

      params[parameter.name] = ComponentParameter(parameter, parameter.name, argument.value, false, argument.stack)
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
  params
end
function (template::Template)(arguments::Vector, namespace::AbstractNamespace, parent::Union{AbstractComponent,Nothing}, stack::Union{ParserStack,Nothing}=nothing)::Union{Component,AbstractError}
  params = matchparams(template, arguments)
  comp = Component(template, params, Dict{Symbol,Any}(), namespace, parent)
  err = evaluateargs!(comp)
  iserror(err) && return err
  parent === nothing || iserror(parent) || push!(parent, comp)
  comp
end
function evaluateargs(comp::AbstractComponent)::Union{Dict,AbstractError}
  args = Dict{Symbol,Any}()
  for param in values(comp.params)
    name = param.name
    if param.evaluated
      args[name] = param.value
    else
      args[name] = eval(param.value, comp.namespace)
      iserror(args[name]) && return args[name]
    end
    if !isa(args[name], param.param.type) && args[name] !== param.param.default
      return ETypeError("argument of type $(typeof(args[name])) does not match spec of parameter $(name)::$(param.param.type)", param.stack !== nothing ? param.stack : ParserStack[])
    end
  end
  args
end
function evaluateargs!(comp::AbstractComponent)::Union{Dict,AbstractError}
  err = evaluateargs(comp)
  iserror(err) && return err
  comp.args = err
end

function query(::AbstractComponent; alias::Symbol)::Vector{AbstractComponent}
  options = AbstractComponent[]
  if alias !== nothing
    append!(options, get(getcompclasses(names), alias, []))
  end
  options
end
function queryone(comp::AbstractComponent; alias::Symbol)::Union{AbstractComponent,Nothing}
  get(query(comp; alias=alias), 1, nothing)
end
