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
            printstyled(stderr, "[ERROR] "; bold = true, color = :red)
            printstyled(stderr, "In Attrape callback: "; bold = true)
            Base.showerror(stderr, e, catch_backtrace())
            print(stderr, "\n")
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
update!(fn::Function, reactant::EReactant; notify::Bool = false) = setvalue!(reactant, fn(getvalue(reactant)); notif = notify)
getobservable(reactant::EReactant) = reactant.observable
isdirty(reactant::EReactant) = reactant.dirty
dirty!(reactant::EReactant, dirt::Bool) = (reactant.dirty = dirt)
function setvalue!(reactant::AbstractReactant{T}, value::T; notif::Bool = false) where {T}
    reactant.value = value
    dirty!(reactant, true)
    notif&& notify(
        reactant
    )
    return value
end


function sync!(
        rea1::Pair{EReactant{T}, <:Union{<:Function, Nothing}},
        rea2::Pair{EReactant{U}, <:Union{<:Function, Nothing}},
        obs::Union{AbstractObserver, Nothing} = nothing
    ) where {T, U}

    let syncing::Bool = false,
            this = first(rea1), uthis = last(rea1),
            other = first(rea2), uother = last(rea2)
        isnothing(uthis) || subscribe!(this, obs) do _, value
            syncing && return
            syncing = true
            try
                notify!(other, convert(U, value |> uthis))
            finally
                syncing = false
            end
        end
        isnothing(uother) || subscribe!(other, obs) do _, value
            syncing && return
            syncing = true
            try
                notify!(this, convert(T, value |> uother))
            finally
                syncing = false
            end
        end
    end
    return
end
