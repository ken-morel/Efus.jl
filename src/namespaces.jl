export DictNamespace, gettemplate, getmodule, addtemplate!, importmodule!

function Base.getindex(names::AbstractNamespace, name::Symbol)
  getname(names, name, nothing)
end


struct ModuleNamespace <: AbstractNamespace
  mod::Module
  parent::Union{Nothing,AbstractNamespace}
  templates::Dict{Symbol,AbstractTemplate}
  modules::Dict{Symbol,TemplateModule}
  componentclasses::Dict{Symbol,Vector{Component}}
  ModuleNamespace(mod::Module) = new(mod, nothing, Dict(), Dict(), Dict())
end
function varstomodule!(mod::Module, namespace::ModuleNamespace)::Module
  for name in names(namespace.mod; all=true, imported=false)
    if !startswith(String(name), "#") && !(getfield(namespace.mod, name) isa Module)
      Core.eval(mod, :($name = $(namespace.mod).$name))
    end
  end

  mod
end
withmodule(fn::Function, names::ModuleNamespace) = fn(names.mod)
function Base.setindex!(names::ModuleNamespace, value, name::Symbol)
  Core.eval(names.mod, :($name = $value))
end
function getname(names::ModuleNamespace, name::Symbol, default)
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
function varstomodule!(mod::Module, names::DictNamespace)::Module
  for (k, v) ∈ names.variables
    Core.eval(mod, :($k = $v))
  end
  if names.parent !== nothing
    varstomodule!(mod, names.parent)
  else
    mod
  end
end
function withmodule(fn::Function, names::DictNamespace)
  mod = Module(Symbol("Efus.Namespace$(rand(UInt64))"), false, false)
  fn(varstomodule!(mod, names))
end

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
function Base.setindex!(names::DictNamespace, value, name::Symbol)
  names.variables[name] = value
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
