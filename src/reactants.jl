abstract type AbstractReactant{T} <: EObject end
function subscribe!(
        fn::Function,
        reactant::AbstractReactant,
        observer::Union{AbstractObserver, Nothing},
    )
    return subscribe!(fn, reactant.observable, observer)
end
function unsubscribe!(
        fn::Function, reactant::AbstractReactant, observer::AbstractObserver,
    )
    return unsubscribe!(reactant.observable, observer, fn)
end
function notify!(reactant::AbstractReactant, value::T) where {T}
    setvalue!(reactant, value)
    notify(getobservable(reactant), value)
    return dirty!(reactant, false)
end
function notify(reactant::AbstractReactant)
    for (_, fn) in getsubscriptions(getobservable(reactant))
        try
            fn(reactant.value)
        catch e
            @warn "Error in reactant subscription callback: " e
        end
    end
    return dirty!(reactant, false)
end


mutable struct EReactant{T} <: AbstractReactant{T}
    value::T
    dirty::Bool
    observable::AbstractObservable
    EReactant(value::T) where {T} = new{T}(value, false, EObservable())
    EReactant{K}(value::Any) where {K} = new{K}(convert(K, value), false, EObservable())
    EReactant(value::T, observable::AbstractObservable) where {T} = new{T}(value, false, observable)
end
getvalue(reactant::EReactant) = reactant.value
getobservable(reactant::EReactant) = reactant.observable
isdirty(reactant::EReactant) = reactant.dirty
dirty!(reactant::EReactant, dirt::Bool) = (reactant.dirty = dirt)
function setvalue!(reactant::AbstractReactant{T}, value::T) where {T}
    reactant.value = value
    return dirty!(reactant, true)
end
