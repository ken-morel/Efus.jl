abstract type AbstractReactant{T} <: EObject end
function subscribe!(
  fn::Function, reactant::AbstractReactant, observer::AbstractObserver,
)
  subscribe!(reactant.observable, observer, fn)
end
function unsubscribe!(
  fn::Function, reactant::AbstractReactant, observer::AbstractObserver,
)
  unsubscribe!(reactant.observable, observer, fn)
end
function notify!(reactant::AbstractReactant, value::T) where T
  setvalue(reactant, value)
  notify(getobservable(reactant), value)
end
function notify(reactant::AbstractReactant)
  for (_, fn) in getsubscriptions(getobservable(reactant))
    try
      fn(reactant.value)
    catch e
      @warn "Error in reactant subscription callback: " e
    end
  end
end



mutable struct EReactant{T} <: AbstractReactant{T}
  value::T
  dirty::Bool
  observable::AbstractObservable
  EReactant(value::T) where T = new{T}(value, false, EObservable())
  EReactant(value::T, observable::AbstractObservable) where T = new{T}(value, false, observable)
end
getvalue(reactant::EReactant) = reactant.value
getobservable(reactant::EReactant) = reactant.observable
isdirty(reactant::EReactant) = reactant.dirty
dirty!(reactant::EReactant, dirt::Bool) = (reactant.dirty = dirt)
function setvalue(reactant::AbstractReactant{T}, value::T) where T
  reactant.value = value
  dirty!(reactant, true)
end
