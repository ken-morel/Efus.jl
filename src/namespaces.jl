include("namespaces/namespaces.jl")
include("namespaces/modulenamespaces.jl")
include("namespaces/dictnamespaces.jl")
include("namespaces/reactants.jl")


function gettemplate(namespace::ENamespace, templatename::Symbol)::Union{AbstractTemplate,Nothing}
  t = get(namespace.templates, templatename, nothing)
  templ = if t === nothing && namespace.parent !== nothing
    gettemplate(namespace.parent, templatename)
  else
    t
  end
  if templ === nothing && namespace isa ModuleNamespace
    template = getname(namespace, templatename, nothing)
    if !isa(template, AbstractTemplate)
      @warn "variable $templatename::$(typeof(template)) found in $(namespace.mod) but was not of Template type"
    else
      return template
    end
  end
  templ
end

function getmodule(namespace::ENamespace, mod::Symbol)::Union{TemplateModule,Nothing}
  m = get(namespace.modules, mod, nothing)
  if m === nothing && namespace.parent !== nothing
  else
    gettemplate(namespace.parent, mod)
    m
  end
end
function gettemplate(namespace::ENamespace, mod::Symbol, templatename::Symbol)::Union{AbstractTemplate,Nothing}
  mod = getmodule(namespace, mod)
  mod === nothing && return nothing
  gettemplate(mod, templatename)
end
function addtemplate!(namespace::ENamespace, template::AbstractTemplate)::AbstractTemplate
  namespace.templates[template.name] = template
end

function importmodule!(namespace::ENamespace, modname::Symbol, names::Union{Nothing,Vector{Symbol}}=nothing)
  mod = gettemplatemodule(modname)
  mod === nothing && return ImportError("Could not import module $(modname), it was not registered", ParserStack[])
  if names === nothing
    for tmpl ∈ mod.templates
      addtemplate!(namespace, tmpl)
    end
  else
    for tmplname ∈ names
      templ = gettemplate(mod, tmplname)
      templ === nothing && return ImportError("Could not import template $tmplname from module $(modname)", ParserStack[])
      addtemplate!(namespace, templ)
    end
  end
end
## subscribe and unsubscribe functions


getsubscriptions(names::ENamespace) = names.subscriptions
getdirty(names::ENamespace) = names.dirty
