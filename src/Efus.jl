module Efus

export getmodule, gettemplate, registertemplatemodule, registertemplate
include("objects.jl")
include("errors.jl")
include("templatebackends.jl")
include("template.jl")
include("component.jl")
include("namespaces.jl")
include("statement.jl")
include("parser.jl")
include("customtemplates.jl")
const TEMPLATE_MODULES = TemplateModule[]
function getmodule(mod::Symbol)::Union{TemplateModule,Nothing}
  modindex = findfirst(tmplmod -> tmplmod.name == mod, TEMPLATE_MODULES)
  modindex === nothing && return nothing
  TEMPLATE_MODULES[modindex]
end
function gettemplate(mod::Symbol, name::Symbol)::Union{Template,Nothing}
  mod = getmodule(mod)
  mod === nothing && return nothing
  gettemplate(mod, name)
end
function registertemplatemodule(name::Symbol, templates::Vector{<:AbstractTemplate})
  exists = findfirst(mod -> mod.name == name, TEMPLATE_MODULES)
  if exists === nothing
    push!(TEMPLATE_MODULES, TemplateModule(name, templates))
  else
    append!(TEMPLATE_MODULES[exists].templates, templates)
  end
end
registertemplatemodule(name::Symbol) = registertemplatemodule(name, Template[])
registertemplate(mod::Symbol, tmpl::Template) = registertemplatemodule(mod, Template[tmpl])


end
