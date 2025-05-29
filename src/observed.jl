"""
    AbstractObserver

Abstract supertype for all observer types in the reactive system.
"""
abstract type AbstractObserver end

"""
    AbstractObservable

Abstract supertype for all observable types in the reactive system.
"""
abstract type AbstractObservable end


"""
    EObserver()

A concrete observer that can subscribe to observables and receive notifications.
"""
struct EObserver
  subscriptions::Vector{Tuple{Union{AbstractObservable,Nothing},Function}}
  EObserver() = new(Vector())
end
"""
    dropsubscriptions!(observer::AbstractObserver, observable::Union{AbstractObservable,Nothing,Missing}, fn::Union{Function,Missing})

Remove subscriptions from the observer matching the given observable and/or function.
If `observable` or `fn` is `missing`, it matches all.
"""
function dropsubscriptions!(
  observer::AbstractObserver,
  observable::Union{AbstractObservable,Nothing,Missing},
  fn::Union{Function,Missing},
)
  observer.subscriptions = filter(observer.subscriptions) do (obsbl, obsfn)
    (observable === missing || obsbl != observable) && (fn === missing || fn != obsfn)
  end
end
"""
    addsubscription!(observer::Observer, observable::Observable, fn::Function)

Add a subscription to the observer for the given observable and callback function.
"""
function addsubscription!(observer::EObserver, observable::EObservable, fn::Function)
  push!(observer.subscriptions, (observable, fn))
end
"""
    unsubscribe!(observer::AbstractObserver, observable::Union{AbstractObservable,Nothing}, fn::Function)

Unsubscribe the observer from the observable for the given function.
Removes the subscription from both observer and observable.
"""
function unsubscribe!(observer::AbstractObserver, observable::Union{AbstractObservable,Nothing}, fn::Function)
  dropsubscriptions!(observer, observable, fn)
  dropsubscriptions!(observable, observer, fn)
end
"""
    unsubscribe!(fn::Function, obsr::AbstractObserver, obsbl::Union{AbstractObservable,Nothing})

Alternate signature for `unsubscribe!` with argument order: function, observer, observable.
"""
unsubscribe!(fn::Function, obsr::AbstractObserver, obsbl::Union{AbstractObservable,Nothing}) = unsubscribe!(obsr, obsbl, fn)




"""
    EObservable()

A concrete observable that can be observed by observers and notify them of changes.
"""
struct EObservable
  subscriptions::Vector{Tuple{Union{AbstractObserver,Nothing},Function}}
  EObservable() = new(Vector())
end
"""
    addsubscription!(observable::Observable, observer::Union{Observer,Nothing}, fn::Function)

Add a subscription to the observable for the given observer and callback function.
"""
function addsubscription!(observable::EObservable, observer::Union{EObserver,Nothing}, fn::Function)
  push!(observable.subscriptions, (observer, fn))
end
"""
    dropsubscriptions!(observable::Union{EObservable,Nothing,Missing}, observer::AbstractObserver, fn::Union{Function,Missing})

Remove subscriptions from the observable matching the given observer and/or function.
If `observer` or `fn` is `missing`, it matches all.
"""
function dropsubscriptions!(
  observable::Union{EObservable,Nothing,Missing},
  observer::AbstractObserver,
  fn::Union{Function,Missing},
)
  observable.subscriptions = filter(observable.subscriptions) do (obsr, obsfn)
    (observer === missing || obsr != observer) && (fn === missing || fn != obsfn)
  end
end
"""
    getsubscriptions(obsbl::Observable) -> Vector{Tuple{Union{AbstractObserver,Nothing},Function}}

Return the list of subscriptions for the given observable.
"""
getsubscriptions(obsbl::EObservable) = obsbl.subscriptions
"""
    notify(observable::AbstractObservable, args...; kwargs...)

Notify all observers of the observable by calling their registered functions with the given arguments.
Catches and warns on errors in observer functions.
"""
function notify(observable::AbstractObservable, args...; kwargs...)
  for (observer, fn) in getsubscriptions(observable)
    try
      fn(observer, args...; kwargs...)
    catch e
      @warn "Error notifying observer" observer "of" observable "with function" fn "and arguments" args ", error: " e
    end
  end
end


"""
    subscribe!(observable::AbstractObservable, observer::Union{AbstractObserver,nothing}, fn::Function)

Subscribe the observer to the observable with the given callback function.
Adds the subscription to both observer and observable.
"""
function subscribe!(observable::AbstractObservable, observer::Union{AbstractObserver,nothing}, fn::Function)
  addsubscription!(observable, observer, fn)
  addsubscription!(observer, observable, fn)
end
"""
    subscribe!(fn::Function, obsbl::AbstractObservable, obsr::AbstractObserver)

Alternate signature for `subscribe!` with argument order: function, observable, observer.
"""
subscribe!(fn::Function, obsbl::AbstractObservable, obsr::AbstractObserver) = subscribe!(obsbl, obsr, fn)


