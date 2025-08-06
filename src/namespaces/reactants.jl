mutable struct ENamespaceReactant <: AbstractReactant{Any}
    observable::EObservable
    observer::EObserver
    name::Symbol
    namespace::AbstractNamespace
end
getvalue(nreact::ENamespaceReactant, default::Any = nothing) = getname(
    nreact.namespace, nreact.name, default
)
getobservable(nreact::ENamespaceReactant) = nreact.observable
isdirty(nreact::ENamespaceReactant) = nreact.name in getdirty(nreact.namespace)
dirty!(reactant::ENamespaceReactant, dirt::Bool) = dirty!(
    reactant.namespace, reactant.name, dirt
)
function setvalue(nreact::ENamespaceReactant, value)
    setindex!(nreact.namespace, value, nreact.name)
    return dirty!(nreact, true)
end
function subscribe!(
        fn::Function, nreact::ENamespaceReactant, observer::AbstractObserver,
    )
    return subscribe!(nreact.observable, observer, fn)
end
function unsubscribe!(
        fn::Function, nreact::ENamespaceReactant, observer::AbstractObserver,
    )
    return unsubscribe!(nreact.observable, observer, fn)
end
function notify!(nreact::ENamespaceReactant, value)
    setvalue(nreact, value)
    return notify(nreact.observable, value)
end
function notify(nreact::ENamespaceReactant)
    return notify(nreact.observable, getvalue(nreact, nothing))
end


function getreactant(namespace::ENamespace, name::Symbol)::ENamespaceReactant
    if haskey(namespace.reactants, name)
        existing_reactant = namespace.reactants[name]
        return existing_reactant
    else
        reactant = ENamespaceReactant(EObservable(), EObserver(), name, namespace)
        subscribe!(reactant.namespace, reactant.observer, [reactant.name]) do
            notify(reactant)
        end
        namespace.reactants[name] = reactant
        return reactant
    end
end
