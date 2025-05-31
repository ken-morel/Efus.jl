export CustomTemplate, ERender, CustomComponent, inlet, outlet
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
  handlers::CustomComponentHandlers
  CustomComponent(
    template::CustomTemplate,
    params::Dict{Symbol,ComponentParameter},
    args::Dict{Symbol,Any},
    namespace::AbstractNamespace,
    parent::Union{AbstractComponent,Nothing},
    code::ECode,
  ) = new(template, params, args, namespace, parent, AbstractComponent[], false, nothing, nothing, code, nothing, nothing, CustomComponentHandlers(nothing, nothing))
end
getnamespace(comp::CustomComponent) = comp.namespace
getmount(::CustomComponent) = nothing
parent(comp::CustomComponent) = comp.parent #TODO: Chech this works
onmount(fn::Function, comp::CustomComponent) = (comp.handlers.onmount = fn)
onrender(fn::Function, comp::CustomComponent) = (comp.handlers.onrender = fn)
function render(comp::CustomComponent)::Union{AbstractError,ERender}
  namespace = DictNamespace(comp.namespace)
  ctx = EvalContext(namespace)
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
function render!(comp::CustomComponent)::Union{AbstractError,ERender}
  renderred = render(comp)
  iserror(renderred) && return renderred
  comp.render = renderred
end
function rerender!(comp::CustomComponent)::Union{AbstractError,ERender}
  comp.render === nothing || unrender!(comp)
  render!(comp.render.render)
end
function unrender!(comp::CustomComponent)
  if comp.render !== nothing && comp.render.render !== nothing
    unmount!(outlet(comp.render.render))
  end
end
renderred(comp::CustomComponent) = comp.render !== nothing


function mount!(comp::CustomComponent)::Union{AbstractError,AbstractMount,Nothing}
  println("rendering")
  if !renderred(comp)
    render = render!(comp)
    iserror(render) && println("oops", render)
    iserror(render) && return render
  end
  comp.render !== nothing || comp.render.render !== nothing || return nothing
  mounted = mount!(outlet(comp.render.render))
  iserror(mounted) && return mounted
  comp.mount = mounted
  comp.handlers.onmount !== nothing && comp.handlers.onmount(comp.mount)
  println("  no error")
  comp.mount
end
function rerender!(comp::CustomComponent)
  println("unrendering")
  unrender!(comp)
  println("rendering")
  render!(comp)
  println("rendered again")
end
function unmount!(comp::CustomComponent)
  !renderred(comp) && return
  render === nothing && return nothing
  unmount!(outlet(comp))
end
function remount!(comp::CustomComponent)
  println("remounting")
  !renderred(comp) && return nothing
  println("unmount first")
  unmount!(comp)
  println("then mount again")
  mount!(comp)
end
function update!(comp::CustomComponent)
  !renderred(comp) && return nothing
  comp.render.render === nothing && return nothing
  update!(comp.render.render)
end
inlet(comp::CustomComponent)::AbstractComponent = comp.inlet === nothing ? nothing : inlet(comp.inlet)
outlet(comp::CustomComponent)::AbstractComponent = comp.outlet === nothing ? nothing : outlet(comp.outlet)



function (template::CustomTemplate)(arguments::Vector, namespace::AbstractNamespace, parent::Union{Component,Nothing}, ::Union{ParserStack,Nothing}=nothing)::Union{CustomComponent,AbstractError}
  params = matchparams(template, arguments)
  iserror(params) && return params
  comp = CustomComponent(template, params, Dict{Symbol,Any}(), namespace, parent, template.code)
  comp.namespace[:self] = comp
  err = evaluateargs!(comp)
  iserror(err) && return err
  err = template.initializer(comp, comp.namespace)
  iserror(err) && return err
  parent === nothing || iserror(parent) || push!(parent, comp)
  comp
end
