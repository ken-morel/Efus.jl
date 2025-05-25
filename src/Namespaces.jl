
struct Namespace <: AbstractNamespace
  variables::Dict{Symbol,EObject}
  templates::Dict{Symbol,Template}
  Namespace() = new(Dict(), Dict())
end

function gettemplate(namespace::Namespace, templatename::Symbol)::Union{Template,Nothing}
  get(namespace.templates, templatename, nothing)
end


