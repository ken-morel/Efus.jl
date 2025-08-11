abstract type AbstractComponent <: EObject end

function Base.getindex(comp::AbstractComponent, key::Symbol)
    return get(getargs(comp), key, nothing)
end
function Base.setindex!(comp::AbstractComponent, value, key::Symbol)
    param = get(comp.params, key, nothing)
    comp.params[key] = ComponentParameter(param !== nothing ? param.param : nothing, key, value, true, nothing)
    comp.dirty = true
    return reevaluateargs!(comp, [key])
end

struct ComponentParameter
    param::Union{TemplateParameter, Nothing}
    name::Symbol
    value::Any
    evaluated::Bool
    stack::Union{ParserStack, Nothing}
end

mutable struct Component{T <: TemplateBackend} <: AbstractComponent
    template::EfusTemplate{T}
    backend::T
    params::Dict{Symbol, ComponentParameter}
    args::Dict{Symbol, Any}
    namespace::AbstractNamespace
    parent::Union{AbstractComponent, Nothing}
    children::Vector{AbstractComponent}
    mount::Union{Nothing, AbstractMount}
    dirty::Bool
    aliases::Vector{Symbol}
    observer::EObserver
    Component(
        template::EfusTemplate{T},
        backend::T,
        params::Dict{Symbol, ComponentParameter},
        args::Dict{Symbol, Any},
        namespace::AbstractNamespace,
        parent::Union{AbstractComponent, Nothing},
    ) where {T} = new{T}(template, backend, params, args, namespace, parent, AbstractComponent[], nothing, false, Symbol[], EObserver())
end
getparam(comp::AbstractComponent, name::Symbol)::Union{ComponentParameter, Nothing} = get(comp.params, name, nothing)
getnamespace(comp::AbstractComponent) = comp.namespace
templatename(comp::AbstractComponent)::Symbol = gettemplate(comp).name
gettemplate(comp::AbstractComponent)::AbstractTemplate = comp.template
getargs(comp::AbstractComponent) = comp.args
getparams(comp::AbstractComponent) = comp.params
isdirty(comp::AbstractComponent) = comp.dirty
dirty!(comp::AbstractComponent, dirt::Bool) = (comp.dirty = dirt)
getmount(comp::Component) = comp.mount
parent(comp::Component) = comp.parent
inlet(comp::Component)::Component = comp
outlet(comp::Component)::Component = comp
getchildren(comp::AbstractComponent) = comp.children


getaliases(comp::AbstractComponent) = comp.aliases
addalias(comp::AbstractComponent, alias::Symbol) = push!(comp.aliases, alias)
removealias(comp::AbstractComponent, alias::Symbol) = pop!(comp.aliases, alias)
hasalias(comp::AbstractComponent, alias::Symbol) = alias ∈ getaliases(comp)


Base.push!(parent::AbstractComponent, child::AbstractComponent) = push!(parent.children, child)
function matchparams(template::AbstractTemplate, arguments::Vector, stack::Union{ParserStack, Nothing} = nothing)::Union{AbstractEfusError, Dict{Symbol, ComponentParameter}}
    params::Dict{Symbol, ComponentParameter} = Dict()
    arguments = arguments[:]
    for parameter in template.parameters
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
    return params
end
"""
    (template::Template)(arguments::Vector, namespace::AbstractNamespace, parent::Union{AbstractComponent,Nothing}, stack::Union{ParserStack,Nothing}=nothing)::Union{Component,AbstractError}

TBW
"""
function (template::EfusTemplate)(arguments::Vector, namespace::AbstractNamespace, parent::Union{AbstractComponent, Nothing}, stack::Union{ParserStack, Nothing} = nothing)::Union{Component, AbstractEfusError}
    params = matchparams(template, arguments)
    iserror(params) && return params
    comp = Component(template, template.backend(), params, Dict{Symbol, Any}(), namespace, parent)
    err = evaluateargs!(comp)
    iserror(err) && return err
    parent === nothing || iserror(parent) || push!(parent, comp)
    return comp
end
init!(::Component) = nothing
function evaluateargs(comp::AbstractComponent; argnames::Union{Nothing, Vector{Symbol}} = nothing)::Union{Dict, AbstractEfusError}
    args = Dict{Symbol, Any}()
    for param in values(comp.params)
        if !isnothing(argnames) && param.name ∉ argnames
            continue
        end
        name = param.name
        if param.evaluated
            args[name] = param.value
        else
            args[name] = Base.eval(param.value, comp.namespace)
            iserror(args[name]) && return args[name]
        end
        if !isa(args[name], param.param.type) && args[name] != param.param.default
            if args[name] isa AbstractReactant
                reactant = args[name]
                args[name] = getvalue(args[name])
                if !isa(args[name], param.param.type) && (param.param.required || args[name] !== param.param.default)
                    return ETypeError("value of evaluated reactant argument of type $(typeof(args[name])) does not match spec of parameter $(name)::$(param.param.type)", param.stack !== nothing ? param.stack : ParserStack[])
                else
                    println("subscribing to ", typeof(reactant))
                    subscribe!(reactant, comp.observer) do value
                        comp[param.param.name] = value
                        update!(comp)
                    end
                end
            else
                try
                    args[name] = Base.convert(param.param.type, args[name])
                catch e
                    Base.display_error(e)
                    return ETypeError("argument of type $(typeof(args[name])) could not be converted to $(name)::$(param.param.type) $e", param.stack !== nothing ? param.stack : ParserStack[])
                end
            end
        end
    end
    return args
end
function evaluateargs!(comp::AbstractComponent)::Union{Dict, AbstractEfusError}
    err = evaluateargs(comp)
    iserror(err) && return err
    return comp.args = err
end
function reevaluateargs!(comp::AbstractComponent, args::Vector{Symbol})::Union{Dict{Symbol, Any}, AbstractEfusError}
    newargs = evaluateargs(comp; argnames = args)
    iserror(newargs) && return newargs
    return merge!(comp.args, newargs)
end

function updateargs!(comp::AbstractComponent, args::Vector{Symbol})::Union{Dict{Symbol, Any}, AbstractEfusError}
    err = reevaluateargs!(comp, args)
    iserror(err) && return err
    append!(comp.dirty, args)
    return err
end
