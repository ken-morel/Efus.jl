export Namespace, gettemplate, getmodule, addtemplate!, importmodule!


struct ModuleNamespace <: AbstractNamespace
  mod::Module
  parent::Union{Nothing,AbstractNamespace}
  templates::Dict{Symbol,Template}
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

struct Namespace <: AbstractNamespace
  variables::Dict{Symbol,EObject}
  templates::Dict{Symbol,Template}
  parent::Union{Nothing,Namespace}
  modules::Dict{Symbol,TemplateModule}
  componentclasses::Dict{Symbol,Vector{Component}}
  Namespace() = new(Dict(), Dict(), nothing, Dict(), Dict())
end
getcompclasses(names::Union{Namespace,ModuleNamespace}) = names.componentclasses

function gettemplate(namespace::Union{Namespace,ModuleNamespace}, templatename::Symbol)::Union{Template,Nothing}
  t = get(namespace.templates, templatename, nothing)
  if t === nothing && namespace.parent !== nothing
    gettemplate(namespace.parent, templatename)
  else
    t
  end
end
function getname(names::Namespace, name::Symbol, default)
  if name in keys(names.variables)
    names.variables[name]
  elseif names.parent !== nothing
    getname(names.parent, name, default)
  else
    default
  end
end
function getmodule(namespace::Union{Namespace,ModuleNamespace}, mod::Symbol)::Union{TemplateModule,Nothing}
  m = get(namespace.modules, mod, nothing)
  if m === nothing && namespace.parent !== nothing
    gettemplate(namespace.parent, mod)
  else
    m
  end
end
function gettemplate(namespace::Union{Namespace,ModuleNamespace}, mod::Symbol, templatename::Symbol)::Union{Template,Nothing}
  mod = getmodule(namespace, mod)
  mod === nothing && return nothing
  gettemplate(mod, templatename)
end
function addtemplate!(namespace::Union{Namespace,ModuleNamespace}, template::Template)::Template
  namespace.templates[template.name] = template
end

function importmodule!(namespace::Union{Namespace,ModuleNamespace}, mod::Symbol, names::Union{Nothing,Vector{Symbol}}=nothing)
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







