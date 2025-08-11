module Efus
using Base: @kwdef
using MacroTools


export getmodule, gettemplate, registertemplatemodule, registertemplate
## compoent.jl
export AbstractComponent, ComponentParameter, Component, CustomComponent

export mount!, unmount!, remount!
export getmount, getparam, getnamespace
export getargs, getnamespace
export onrender, onmount

export CustomTemplate, unrender!, render, render!
export ERender

export evaluateargs!, reevaluateargs!, updateargs!
export evaluateargs
export gettemplate, isdirty, dirty!
export inlet, outlet, getchildren

export getaliases, addalias, removealias, hasalias

## componentquery.jl
export query, queryone
## errors.jl
export iserror, format
## namespaces
export getmodule, importmodule!
export gettemplate, addtemplate!

export DictNamespace, ModuleNamespace

export getname

export AbstractNamespaceReactant, AbstractNamespace

export varstomodule!, withmodule
#objects
export resolve
export EObject, EMirrorObject
export ESize, unit, ESide, EOrient
export EHAlign, EVAlign, EGeometry, EEdgeInsets, ESquareGeometry

#observed
export dropsubscriptions!, addsubscription!, subscribe!, unsubscribe!, getsubscriptions
export EObserver, EObservable, notify
export @redirectobservablemethods
#parser.jl does not export
export @efuseval_str, @efus_str, @efusthrow_str
export @efuspreeval_str
#reactants.jl
export EReactant
export getvalue, getobservable, setvalue!, notify!
export sync!

# statement.jl
export EfusEvalContext, ECodeBlock, ECode, EfusTemplate
export eval!


include("objects.jl")
include("observed.jl")
include("reactants.jl")
include("errors.jl")
include("templatebackends.jl")
include("template.jl")
include("component.jl")
include("namespaces.jl")
include("statement.jl")
include("parser.jl")
include("customtemplates.jl")
include("componentquery.jl")
const TEMPLATE_MODULES = TemplateModule[]
function gettemplatemodule(mod::Symbol)::Union{TemplateModule, Nothing}
    modindex = findfirst(tmplmod -> tmplmod.name == mod, TEMPLATE_MODULES)
    modindex === nothing && return nothing
    return TEMPLATE_MODULES[modindex]
end
function gettemplate(mod::Symbol, name::Symbol)::Union{EfusTemplate, Nothing}
    mod = gettemplatemodule(mod)
    mod === nothing && return nothing
    return gettemplate(mod, name)
end
function registertemplatemodule(name::Symbol, templates::Vector{<:AbstractTemplate})
    exists = findfirst(mod -> mod.name == name, TEMPLATE_MODULES)
    return if exists === nothing
        push!(TEMPLATE_MODULES, TemplateModule(name, templates))
    else
        append!(TEMPLATE_MODULES[exists].templates, templates)
    end
end
registertemplatemodule(name::Symbol) = registertemplatemodule(name, EfusTemplate[])
registertemplate(mod::Symbol, tmpl::EfusTemplate) = registertemplatemodule(mod, EfusTemplate[tmpl])
end
