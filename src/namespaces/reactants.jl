mutable struct ENamespaceReactant{T} <: AbstractReactant{T}
  observable::EObservable
  observer::EObserver
  name::Symbol
  namespace::AbstractNamespace
end
getvalue(nreact::ENamespaceReactant{T}, default::Any=nothing) where T = getname(
  nreact.namespace, nreact.name, default
)
getobservable(nreact::ENamespaceReactant) = nreact.observable
isdirty(nreact::ENamespaceReactant) = nreact.name in getdirty(nreact.namespace)
dirty!(reactant::ENamespaceReactant, dirt::Bool) = dirty!(
  reactant.namespace, reactant.name, dirt
)
function setvalue(nreact::ENamespaceReactant{T}, value::T) where T
  setindex!(nreact.namespace, value, nreact.name)
  dirty!(nreact, true)
end
function subscribe!(
  fn::Function, nreact::ENamespaceReactant, observer::AbstractObserver,
)
  subscribe!(nreact.observable, observer, fn)
end
function unsubscribe!(
  fn::Function, nreact::ENamespaceReactant, observer::AbstractObserver,
)
  unsubscribe!(nreact.observable, observer, fn)
end
function notify!(nreact::ENamespaceReactant, value::T) where T
  setvalue(nreact, value)
  notify(nreact)
end
function notify(nreact::ENamespaceReactant)
  for (_, fn) in getsubscriptions(getobservable(nreact))
    try
      fn()
    catch e
      @warn "Error in namespace reactant $(nreact.name) subscription callback: " e
    end
  end
end


