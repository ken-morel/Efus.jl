module Efus
include("Objects.jl")
include("Errors.jl")
include("TemplateBackends.jl")
include("Template.jl")
include("Namespaces.jl")
include("Statement.jl")
include("Parser.jl")
const TEMPLATE_MODULES = TemplateModule[]
function getmodule(mod::Symbol)::Union{TemplateModule,Nothing}
  modindex = findfirst(TEMPLATE_MODULES) do tmplmod
    tmplmod.name == mod
  end
  modindex === nothing && return nothing
  TEMPLATE_MODULES[modindex]
end
function gettemplate(mod::Symbol, name::Symbol)::Union{Template,Nothing}
  mod = getmodule(mod)
  mod === nothing && return nothing
  gettemplate(mod, name)
end
function registertemplatemodule(name::Symbol, templates::Vector{Template})
  push!(TEMPLATE_MODULES, TemplateModule(name, templates))
end
end
