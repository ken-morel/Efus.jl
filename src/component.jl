struct ComponentParameter
  param::Union{TemplateParameter,Nothing}
  name::Symbol
  value::Any
  evaluated::Bool
  stack::Union{ParserStack,Nothing}
end

mutable struct Component <: EObject
  template::Template
  params::Dict{Symbol,ComponentParameter}
  args::Dict{Symbol,Any}
  namespace::AbstractNamespace
  parent::Union{Component,Nothing}
  children::Vector{Component}
  mount::Union{Nothing,AbstractMount}
  dirty::Bool
  Component(template::Template,
    params::Dict{Symbol,ComponentParameter},
    args::Dict{Symbol,Any},
    namespace::AbstractNamespace,
    parent::Union{Component,Nothing},
  ) = new(template, params, args, namespace, parent, Component[], nothing, false)
end
getmount(comp::Component) = comp.mount
mount!(_::TemplateBackend, _::Component) = throw("Mounting not supported by backend")
unmount!(_::TemplateBackend, _::Component) = throw("Unmounting not supported by backend")
update!(_::TemplateBackend, _::Component) = throw("Updating not supported by backend")
mount!(component::Component)::Union{Nothing,AbstractMount} = mount!(component.template.backend, component)
unmount!(component::Component) = unmount!(component.template.backend, component)
update!(component::Component) = update!(component.template.backend, component)
parent(comp::Component) = comp.parent
function master(comp::Component)
  while parent(comp) !== nothing
    comp = parent(comp)
  end
  comp
end
function Base.getindex(comp::Component, key::Symbol)
  get(comp.args, key, nothing)
end
function Base.setindex!(comp::Component, value, key::Symbol)
  param = get(comp.params, key, nothing)
  comp.params[key] = ComponentParameter(param !== nothing ? param.param : nothing, key, value, true, nothing)
  comp.dirty = true
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
  comp = Component(template, params, Dict{Symbol,Any}(), namespace, parent)
  err = evaluateargs!(comp)
  iserror(err) && return err
  parent === nothing || iserror(parent) || push!(parent, comp)
  comp
end
function evaluateargs(comp::Component)::Union{Dict,AbstractError}
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
function evaluateargs!(comp::Component)::Union{Dict,AbstractError}
  err = evaluateargs(comp)
  iserror(err) && return err
  comp.args = err
end

function query(comp::Component; alias::Symbol)::Vector{Component}
  options = Component[]
  if alias !== nothing
    append!(options, get(getcompclasses(names), alias, []))
  end
  options
end
function queryone(comp::Component; alias::Symbol)::Union{Component,Nothing}
  get(query(comp; alias=alias), 1, nothing)
end
