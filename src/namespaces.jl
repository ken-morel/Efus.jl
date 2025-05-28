export DictNamespace, gettemplate, getmodule, addtemplate!, importmodule!


struct ModuleNamespace <: AbstractNamespace
  mod::Module
  parent::Union{Nothing,AbstractNamespace}
  templates::Dict{Symbol,AbstractTemplate}
  modules::Dict{Symbol,TemplateModule}
  componentclasses::Dict{Symbol,Vector{Component}}
  ModuleNamespace(mod::Module) = new(mod, nothing, Dict(), Dict(), Dict())
end
function getname(names::ModuleNamespace, name::Symbol, default)
  println("getting name $name in mod")
  if name in propertynames(names.mod)
    getproperty(names.mod, name)
  elseif names.parent !== nothing
    getname(names.parent, name, default)
  else
    default
  end
end

struct DictNamespace <: AbstractNamespace
  variables::Dict{Symbol,EObject}
  templates::Dict{Symbol,AbstractTemplate}
  parent::Union{Nothing,AbstractNamespace}
  modules::Dict{Symbol,TemplateModule}
  componentclasses::Dict{Symbol,Vector{Component}}
  DictNamespace() = new(Dict(), Dict(), nothing, Dict(), Dict())
  DictNamespace(parent::Union{AbstractNamespace,Nothing}) = new(Dict(), Dict(), parent, Dict(), Dict())
end
getcompclasses(names::Union{DictNamespace,ModuleNamespace}) = names.componentclasses

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
function getname(names::DictNamespace, name::Symbol, default)
  if name in keys(names.variables)
    names.variables[name]
  elseif names.parent !== nothing
    getname(names.parent, name, default)
  else
    default
  end
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

function importmodule!(namespace::Union{DictNamespace,ModuleNamespace}, mod::Symbol, names::Union{Nothing,Vector{Symbol}}=nothing)
  mod = getmodule(mod)
  mod === nothing && return ImportError("Could not import module $(mod)", ParserStack[])
  if names === nothing
    for tmpl ∈ mod.templates
      addtemplate!(namespace, tmpl)
    end
  else
    for tmplname ∈ names
      templ = gettemplate(mod, tmplname)
      templ === nothing && return ImportError("Could not import template $tmplname from module $(mod)", ParserStack[])
      addtemplate!(namespace, templ)
    end
  end

end
