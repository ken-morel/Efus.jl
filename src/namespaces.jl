include("namespaces/namespaces.jl")
include("namespaces/modulenamespaces.jl")
include("namespaces/dictnamespaces.jl")



function gettemplate(namespace::Union{DictNamespace,ModuleNamespace}, templatename::Symbol)::Union{AbstractTemplate,Nothing}
  t = get(namespace.templates, templatename, nothing)
  templ = if t === nothing && namespace.parent !== nothing
    gettemplate(namespace.parent, templatename)
  else
    t
  end
  if templ === nothing && namespace isa ModuleNamespace
    template = getname(namespace, templatename, nothing)
    template isa AbstractTemplate && return template
  end
  templ
end

function getmodule(namespace::Union{DictNamespace,ModuleNamespace}, mod::Symbol)::Union{TemplateModule,Nothing}
  m = get(namespace.modules, mod, nothing)
  if m === nothing && namespace.parent !== nothing
  else
    gettemplate(namespace.parent, mod)
    m
  end
end
function gettemplate(namespace::Union{DictNamespace,ModuleNamespace}, mod::Symbol, templatename::Symbol)::Union{AbstractTemplate,Nothing}
  mod = getmodule(namespace, mod)
  mod === nothing && return nothing
  gettemplate(mod, templatename)
end
function addtemplate!(namespace::Union{DictNamespace,ModuleNamespace}, template::AbstractTemplate)::AbstractTemplate
  namespace.templates[template.name] = template
end

function importmodule!(namespace::Union{DictNamespace,ModuleNamespace}, modname::Symbol, names::Union{Nothing,Vector{Symbol}}=nothing)
  mod = getmodule(modname)
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
function dropsubscriptions!()
  if vars === nothing
    names.subscriptions = filter(names.subscriptions) do (obsr, obsfn, obsvars)
      (obsr != observer && obsfn != fn)
    end
  else
    for (idx, subscription) in enumerate(names.subscriptions)
      obsr, obsfn, obsvars = subscription
      if obsr == observer && obsfn != fn
        names.subscriptions[idx] = (obsr, obsfn, setdiff(obsvars, vars))
      end
    end
  end
end

getcompclasses(names::Union{DictNamespace,ModuleNamespace}) = names.componentclasses
getsubscriptions(names::Union{DictNamespace,ModuleNamespace}) = names.subscriptions
getdirty(names::Union{DictNamespace,ModuleNamespace}) = names.dirty
