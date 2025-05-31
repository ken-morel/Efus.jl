mutable struct ENamespaceReactant <: AbstractReactant{Any}
  observable::EObservable
  observer::EObserver
  name::Symbol
  namespace::AbstractNamespace
end
getvalue(nreact::ENamespaceReactant, default::Any=nothing) = getname(
  nreact.namespace, nreact.name, default
)
getobservable(nreact::ENamespaceReactant) = nreact.observable
isdirty(nreact::ENamespaceReactant) = nreact.name in getdirty(nreact.namespace)
dirty!(reactant::ENamespaceReactant, dirt::Bool) = dirty!(
  reactant.namespace, reactant.name, dirt
)
function setvalue(nreact::ENamespaceReactant, value)
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

function subscribe!(reactant::ENamespaceReactant)
  subscribe!(reactant.namespace, reactant.observer, [reactant.name]) do
    notify(reactant)
  end
end


function getreactant(namespace::ENamespace, name::Symbol)::ENamespaceReactant
  if haskey(namespace.reactants, name)
    existing_reactant = namespace.reactants[name]
    return existing_reactant
  else
    reactant = ENamespaceReactant(EObservable(), EObserver(), name, namespace)
    subscribe!(reactant)
    namespace.reactants[name] = reactant
    return reactant
  end
end
