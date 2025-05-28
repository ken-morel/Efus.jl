export CustomTemplate, ERender, CustomComponent, inlet, outlet

struct CustomTemplate <: AbstractTemplate
  name::Symbol
  parameters::Vector{TemplateParameter}
  code::ECode
end
struct ERender
  render::Union{AbstractComponent,Nothing}
  context::EvalContext
end
mutable struct CustomComponent <: AbstractComponent
  template::CustomTemplate
  params::Dict{Symbol,ComponentParameter}
  args::Dict{Symbol,Any}
  namespace::AbstractNamespace
  parent::Union{AbstractComponent,Nothing}
  children::Vector{AbstractComponent}
  dirty::Bool
  outlet::Union{AbstractComponent,Nothing}
  inlet::Union{AbstractComponent,Nothing}
  code::ECode
  render::Union{ERender,Nothing}
  mount::Union{AbstractMount,Nothing}
  CustomComponent(template::AbstractTemplate,
    params::Dict{Symbol,ComponentParameter},
    args::Dict{Symbol,Any},
    namespace::AbstractNamespace,
    parent::Union{AbstractComponent,Nothing},
    code::ECode
  ) = new(template, params, args, namespace, parent, AbstractComponent[], false, nothing, nothing, code, nothing, nothing)
end
getmount(::CustomComponent) = nothing
parent(comp::CustomComponent) = comp.parent #TODO: Chech this works

function render(comp::CustomComponent)::Union{AbstractError,ERender}
  namespace = DictNamespace(comp.namespace)
  ctx = EvalContext(namespace)
  renderred = eval!(ctx, comp.code)
  iserror(renderred) && return renderred
  comp.outlet = renderred
  ERender(renderred, ctx)
end
function render!(comp::CustomComponent)::Union{AbstractError,ERender}
  comp.render = render(comp)
end
renderred(comp::CustomComponent) = comp.render !== nothing


function mount!(comp::CustomComponent)
  if !renderred(comp)
    render!(comp)
  end
  comp.render !== nothing || comp.render.render !== nothing || return nothing
  comp.mount = mount!(outlet(comp.render.render))
end
function unmount!(comp::CustomComponent)
  if !renderred(comp)
    render!(comp)
  end
  render = comp.render
  render === nothing && return nothing
  unmount!(outlet(render))
end
function update!(comp::CustomComponent)
  !renderred(comp) && return nothing
  comp.render.render === nothing && return nothing
  update!(outlet(comp.render.render))
end
inlet(comp::CustomComponent)::AbstractComponent = inlet(comp.inlet)
outlet(comp::CustomComponent)::AbstractComponent = inlet(comp.inlet)



function (template::CustomTemplate)(arguments::Vector, namespace::AbstractNamespace, parent::Union{Component,Nothing}, ::Union{ParserStack,Nothing}=nothing)::Union{CustomComponent,AbstractError}
  params = matchparams(template, arguments)
  iserror(params) && return params
  comp = CustomComponent(template, params, Dict{Symbol,Any}(), namespace, parent, template.code)
  err = evaluateargs!(comp)
  iserror(err) && return err
  parent === nothing || iserror(parent) || push!(parent, comp)
  comp
end
