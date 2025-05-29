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
