
struct Namespace <: AbstractNamespace
  variables::Dict{Symbol,EObject}
  templates::Dict{Symbol,Template}
  modules::Dict{Symbol,TemplateModule}
  Namespace() = new(Dict(), Dict())
end

function gettemplate(namespace::Namespace, templatename::Symbol)::Union{Template,Nothing}
  get(namespace.templates, templatename, nothing)
end
function getmodule(namespace::Namespace, mod::Symbol)::Union{TemplateModule,Nothing}
  get(namespace.modules, mod, nothing)
end
function gettemplate(namespace::Namespace, mod::Symbol, templatename::Symbol)::Union{Template,Nothing}
  mod = getmodule(namespace, mod)
  mod === nothing && return nothing
  gettemplate(mod, templatename)
end
function addtemplate!(namespace::Namespace, template::Template)::Template
  namespace.templates[template.name] = template
end


