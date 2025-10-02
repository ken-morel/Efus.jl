using FunctionWrappers


export Reactant, Catalyst, Reaction, AbstractReaction
export getvalue, setvalue!, catalyze!, inhibit!, denature!
export resolve, MayBeReactive
export AbstractReactive, Reactor


"""
    abstract type AbstractReactive{T} end

The abstract reactive is the supertype for every
reactive value, where T is the type of the
contained value.
A reactive value supports setvalue!, getvalue
methods. And should have a .reactions attribute.
"""
abstract type AbstractReactive{T} end


abstract type AbstractReaction{T} end

const ReactiveCallback{T} = FunctionWrapper{Any, Tuple{<:AbstractReactive{T}}}

"""
Setvalue set's the value of a given AbstractReactive{T}
object.
It accepts a `notify` optional keyword argument which if 
set to false, prevents it from notifying subscribed values 
about it's change
"""
function setvalue! end


"""
    struct Catalyst

A catalyst is a container and manager
for subscribing to reactants.

Catalysts support the `catalyze!`,
and `denature!` functions.
"""
struct Catalyst
    reactions::Vector{AbstractReaction}

    """
    Construct a catalyst with no reactions.
    """
    Catalyst() = new([])
end


const REACTOR_SETTER{T} = FunctionWrapper{Any, Tuple{T}}
const REACTOR_GETTER{T} = FunctionWrapper{T, Tuple{}}

"""
    mutable struct Reactor{T} <: AbstractReactive{T}

A reactor is a reactive container that derives its value
from another value, it can also be used to wrap
another or more reactants, transforming their values.

A reactor is said to be `fouled` when one of it 
dependencies has changed, and the value was not 
yet updated.
"""
mutable struct Reactor{T} <: AbstractReactive{T}
    getter::REACTOR_GETTER{T}
    setter::Union{REACTOR_SETTER{T}, Nothing}
    const content::Vector{AbstractReactive}
    const reactions::Vector{AbstractReaction{T}}
    const catalyst::Catalyst
    value::T
    fouled::Bool
    eager::Bool

    function Reactor{T}(
            getter::Function, setter::Union{Function, Nothing}, content::Vector{<:AbstractReactive};
            eager::Bool = false, initial = nothing,
        )::Reactor{T} where {T}
        getter = REACTOR_GETTER{T}(getter)
        setter = if !isnothing(setter)
            REACTOR_SETTER{T}(setter)
        end
        initial = isnothing(initial) ? getter() : convert(T, initial)
        r = new{T}(getter, setter, [], [], Catalyst(), initial, false, eager)
        callback = (_) -> begin
            r.fouled = true
            eager && getvalue(r)
            notify(r)
        end
        for reactant in content
            push!(r.content, reactant)
            catalyze!(r.catalyst, reactant, callback)
        end
        return r
    end
    Reactor(
        ::Type{T}, getter::Function, setter::Union{Function, Nothing}, content::Vector{<:AbstractReactive};
        eager::Bool = false,
    ) where {T} = Reactor{T}(getter, setter, content; eager)

    function Reactor(
            getter::Function, setter::Union{Function, Nothing}, content::Vector{<:AbstractReactive};
            eager::Bool = false,
        )
        initial = getter()
        type = typeof(initial)
        return Reactor{type}(getter, setter, content; eager, initial)
    end
end

isfouled(r::Reactor) = r.fouled

"""
    function getvalue(r::Reactor{T})::T where {T}

Get the value of a reactor, recomputing the 
value if one of it dependencies changed(
isfouled(r) is true).
"""
function getvalue(r::Reactor{T})::T where {T}
    if r.fouled
        r.value = r.getter()
        r.fouled = false
    end
    return r.value
end
function setvalue!(r::Reactor{T}, new_value; notify::Bool = true) where {T}
    if isnothing(r.setter)
        r.value = convert(T, new_value)
    else
        r.setter(convert(T, new_value))
    end
    r.fouled = true
    notify && for reaction in copy(r.reactions)
        reaction.callback(r)
    end
    return
end

"""
    mutable struct Reactant{T} <: AbstractReactive{T}

Reactants are the builtin base for reactivity. They 
contain a value of type `T`, a list of reactions and 
notified all catalysts when it's setvalue! is called
"""
mutable struct Reactant{T} <: AbstractReactive{T}
    value::T
    reactions::Vector{AbstractReaction{T}}

    Reactant{T}(value) where {T} = new{T}(convert(T, value), [])
    Reactant(value::T) where {T} = new{T}(value, [])
end

"""
    struct Reaction{T} <: AbstractReaction{T}

A reaction are internaly used by catalysts and 
instances of [AbstractReactive](@ref).
They store the catalyst, reactive and callback.
They are returned when [catalyze!](@ref) is called 
and can be [inhibit!](@ref)-ed.
"""
struct Reaction{T} <: AbstractReaction{T}
    reactant::AbstractReactive{T}
    catalyst::Catalyst
    callback::ReactiveCallback{T}
end


getvalue(r::Reactant{T}) where {T} = r.value::T

function setvalue!(r::Reactant{T}, new_value; notify::Bool = true) where {T}
    r.value = convert(T, new_value)
    notify && for reaction in copy(r.reactions)
        reaction.callback(r)
    end
    return r
end


"""
    function catalyze!(c::Catalyst, r::AbstractReactive{T}, callback::Function)::Reaction{T} where {T}
    catalyze!(fn::Function, c::Catalyst, r::AbstractReactive{T}) where {T}

Subscribes and calls `callback` everytime `r` notifies.
r should be a function which takes a single argument, the 
AbstractReactive instance which was subscribed, and 
it can then call [getvalue](@ref), on it.
Not that this should preferably not be done here, 
since the getvalue may trigger a computation, usualy
you may instead want to notify ui components that 
something changed, and compute the result only 
when updating, so as to limit unnecesarry computations.

## Example

```julia
c = Catalyst()
r = Reactant(1)
catalyze!(c, r) do reactant
    println(getvalue(reactant))
end
```
"""
function catalyze! end

function catalyze!(c::Catalyst, r::AbstractReactive{T}, callback::Function)::Reaction{T} where {T}
    wrapped_callback = ReactiveCallback{T}(callback)

    reaction = Reaction{T}(r, c, wrapped_callback)

    push!(c.reactions, reaction)
    push!(r.reactions, reaction)
    return reaction
end

catalyze!(fn::Function, c::Catalyst, r::AbstractReactive{T}) where {T} = catalyze!(c, r, fn)

"""
    function inhibit!(catalyst::Catalyst, reactant::AbstractReactive, callback::Union{Function, Nothing} = nothing)

Searches and inhibit all reactions between the catalyst and reactant, if a callback is 
passed, it checks for a reaction which has that callback.
returns the number of inhibited reactions.
"""
function inhibit! end

function inhibit!(catalyst::Catalyst, reactant::AbstractReactive, callback::Union{Function, Nothing} = nothing)
    reactions_to_inhibit = if isnothing(callback)
        filter(catalyst.reactions) do sub
            sub.reactant == reactant
        end
    else
        filter(catalyst.reactions) do sub
            sub.reactant == reactant && sub.callback == callback
        end
    end

    for reaction in reactions_to_inhibit
        inhibit!(reaction)
    end
    return length(reactions_to_inhibit)
end

"""
    inhibit!(r::Reaction)

Stops and removes a single, specific Reaction. This is the low-level implementation.
"""
function inhibit!(r::Reaction)
    filter!(!=(r), r.reactant.reactions)
    filter!(!=(r), r.catalyst.reactions)
    return
end

"""
    denature!(c::Catalyst)

Stops all reactions being managed by the Catalyst.

This is the primary cleanup function to be called when a UI component
is destroyed, preventing memory leaks.
"""
function denature!(c::Catalyst)
    for reaction in copy(c.reactions)
        inhibit!(reaction)
    end
    return
end


function notify(r::Reactor)
    for reaction in copy(r.reactions)
        reaction.callback(r)
    end
    #PERF: Trace time and log if too long
    return
end

"""
    const MayBeReactive{T} = Union{AbstractReactive{T}, T}

Use this in cases you deal with values like component
arguments which may be an instance of abstract reactive.

You can then call resolve() on them which 
"""
const MayBeReactive{T} = Union{AbstractReactive{T}, T}

"""
    converter(::Type{AbstractReactive{T}}, r::AbstractReactive{K}) where {T, K}

Creates a reactor which subscribes and get's it value 
from converting that of the other and set's it with another
conversion.
"""
converter(::Type{AbstractReactive{T}}, r::AbstractReactive{K}) where {T, K} = Reactor{T}(
    () -> convert(T, getvalue(r)),
    (v::T) -> setvalue!(r, convert(K, v)),
    [r],
)

public converter


"""
    resolve(r::MayBeReactive{T}) where {T}
    resolve(::Type{T}, r::MayBeReactive) where {T}

Resolve returns r if it is of type T, else calls getvalue on it,
use to get the actual value of a [MayBeReactive](@ref).
"""
function resolve end

resolve(r::MayBeReactive{T}) where {T} = resolve(T, r)
resolve(::Type{T}, r::MayBeReactive) where {T} = r isa T ? r : getvalue(r)
