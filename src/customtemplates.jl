mutable struct CustomComponentHandlers
  onrender::Union{Function,Nothing}
  onmount::Union{Function,Nothing}
end
struct CustomTemplate <: AbstractTemplate
  initializer::Function
  name::Symbol
  parameters::Vector{TemplateParameter}
  code::ECode
  CustomTemplate(
    initializer::Function,
    name::Symbol,
    parameters::Vector{TemplateParameter},
    code::ECode,
  ) = new(initializer, name, parameters, code)
  CustomTemplate(
    initializer::Function,
    name::Symbol,
    parameters::Vector{Pair},
    code::ECode,
  ) = new(initializer, name, convert.((TemplateParameter,), parameters), code)

end

struct ERender
  render::Union{AbstractComponent,Nothing}
  context::EfusEvalContext
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
  handlers::CustomComponentHandlers
  aliases::Vector{Symbol}
  CustomComponent(
    template::CustomTemplate,
    params::Dict{Symbol,ComponentParameter},
    args::Dict{Symbol,Any},
    namespace::AbstractNamespace,
    parent::Union{AbstractComponent,Nothing},
    code::ECode,
  ) = new(template, params, args, namespace, parent, AbstractComponent[], false, nothing, nothing, code, nothing, nothing, CustomComponentHandlers(nothing, nothing), Symbol[])
end
getnamespace(comp::CustomComponent) = comp.namespace
getmount(::CustomComponent) = nothing
parent(comp::CustomComponent) = comp.parent #TODO: Chech this works
onmount(fn::Function, comp::CustomComponent) = (comp.handlers.onmount = fn)
onrender(fn::Function, comp::CustomComponent) = (comp.handlers.onrender = fn)
function render(comp::CustomComponent)::Union{AbstractEfusError,ERender}
  ctx = EfusEvalContext(comp.namespace)
  renderred = eval!(ctx, comp.code)
  iserror(renderred) && return renderred
  if inlet(renderred) !== nothing
    child = inlet(renderred)
    if comp.parent !== nothing
      parent = outlet(comp.parent)
      child.parent = parent
    end
  end
  comp.outlet = renderred
  render = ERender(renderred, ctx)
  comp.handlers.onrender !== nothing && comp.handlers.onrender(render)
  render
end
function render!(comp::CustomComponent)::Union{AbstractEfusError,ERender}
  renderred = render(comp)
  iserror(renderred) && return renderred
  comp.render = renderred
end
function rerender!(comp::CustomComponent)::Union{AbstractEfusError,ERender}
  comp.render === nothing || unrender!(comp)
  render!(comp)
end
function unrender!(comp::CustomComponent)
  if comp.render !== nothing && comp.render.render !== nothing
    unmount!(outlet(comp.render.render))
  end
end
renderred(comp::CustomComponent) = comp.render !== nothing


function mount!(comp::CustomComponent)::Union{AbstractEfusError,AbstractMount,Nothing}
  if !renderred(comp)
    render = render!(comp)
    iserror(render) && return render
  end
  comp.render !== nothing || comp.render.render !== nothing || return nothing
  mounted = mount!(outlet(comp.render.render))
  iserror(mounted) && return mounted
  comp.mount = mounted
  comp.handlers.onmount !== nothing && comp.handlers.onmount(comp.mount)
  comp.mount
end

function unmount!(comp::CustomComponent)
  !renderred(comp) && return
  render === nothing && return nothing
  unmount!(outlet(comp))
end
function remount!(comp::CustomComponent)
  !renderred(comp) && return nothing
  unmount!(comp)
  mount!(comp)
end
function update!(comp::CustomComponent)
  !renderred(comp) && return nothing
  comp.render.render === nothing && return nothing
  update!(comp.render.render)
end
inlet(comp::CustomComponent)::AbstractComponent = comp.inlet === nothing ? nothing : inlet(comp.inlet)
outlet(comp::CustomComponent)::AbstractComponent = comp.outlet === nothing ? nothing : outlet(comp.outlet)



function (template::CustomTemplate)(
  arguments::Vector,
  namespace::AbstractNamespace,
  parent::Union{Component,Nothing}=nothing,
  stack::Union{ParserStack,Nothing}=nothing,
)::Union{CustomComponent,AbstractEfusError}
  params = matchparams(template, arguments, stack)
  iserror(params) && return params
  comp = CustomComponent(
    template,
    params,
    Dict{Symbol,Any}(),
    DictNamespace(namespace),
    parent,
    template.code,
  )
  comp.namespace[:self] = comp
  err = evaluateargs!(comp)
  iserror(err) && return err
  err = template.initializer(comp, comp.namespace)
  iserror(err) && return err
  parent === nothing || iserror(parent) || push!(parent, comp)
  comp
end
function (template::CustomTemplate)()
  template()
end
