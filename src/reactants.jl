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

    Reactor{T}(getter::REACTOR_GETTER{T}, setter::Union{REACTOR_SETTER{T}, Nothing}, val::T) where {T} = new{T}(
        getter,
        setter,
        [],
        [],
        Catalyst(),
        val,
        false
    )
    function Reactor{T}(getter::Function, setter::Union{Function, Nothing}, content::Vector{<:AbstractReactive})::Reactor{T} where {T}
        getter = REACTOR_GETTER{T}(getter)
        setter = if !isnothing(setter)
            REACTOR_SETTER{T}(setter)
        end
        r = Reactor{T}(getter, setter, getter())
        callback = (_) -> r.fouled = true
        for reactant in content
            push!(r.content, reactant)
            catalyze!(r.catalyst, reactant, callback)
        end
        return r
    end
    Reactor(::Type{T}, getter::Function, setter::Union{Function, Nothing}, content::Vector{<:AbstractReactive}) where {T} = Reactor{T}(getter, setter, content)
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
function setvalue!(r::Reactor{T}, new_value::T) where {T}
    r.fouled = true
    isnothing(r.setter) || r.setter(new_value)
    return
end

mutable struct Reactant{T} <: AbstractReactive{T}
    value::T
    reactions::Vector{AbstractReaction{T}}

    Reactant{T}(value) where {T} = new{T}(convert(T, value), [])
    Reactant(value::T) where {T} = new{T}(value, [])
end

struct Reaction{T} <: AbstractReaction{T}
    reactant::AbstractReactive{T}
    catalyst::Catalyst
    callback::ReactiveCallback{T}
end


function getvalue(r::Reactant{T})::T where {T}
    return r.value
end

function setvalue!(r::Reactant{T}, new_value::T) where {T}
    r.value = new_value
    for reaction in r.reactions
        reaction.callback(r)
    end
    return r
end


function catalyze!(c::Catalyst, r::AbstractReactive{T}, callback::Function)::Reaction{T} where {T}
    wrapped_callback = ReactiveCallback{T}(callback)

    reaction = Reaction{T}(r, c, wrapped_callback)

    push!(c.reactions, reaction)
    push!(r.reactions, reaction)
    return reaction
end

catalyze!(fn::Function, c::Catalyst, r::AbstractReactive{T}) where {T} = catalyze!(c, r, fn)

function inhibit!(catalyst::Catalyst, reactant::AbstractReactive, callback::Function)
    reactions_to_inhibit = filter(catalyst.reactions) do sub
        sub.reactant === reactant && sub.callback.func === callback
    end

    for reaction in reactions_to_inhibit
        inhibit!(reaction)
    end
    return
end

function inhibit!(catalyst::Catalyst, reactant::AbstractReactive)
    reactions_to_inhibit = filter(catalyst.reactions) do sub
        sub.reactant === reactant
    end

    for reaction in reactions_to_inhibit
        inhibit!(reaction)
    end
    return
end

"""
    inhibit!(r::Reaction)

Stops and removes a single, specific Reaction. This is the low-level implementation.
"""
function inhibit!(r::Reaction)
    filter!(!==(r), r.reactant.reactions)
    filter!(!==(r), r.catalyst.reactions)
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

function notify!(r::Reactor)
    for reaction in r.reactions
        reaction.callback(r.value)
    end
    #PERF: Trace time and log if too long
    return
end

const MayBeReactive{T} = Union{AbstractReactive{T}, T}

Base.convert(::Type{AbstractReactive{T}}, r::AbstractReactive{K}) where {T, K} = Reactor{T}(
    () -> convert(T, getvalue(r)),
    (v::T) -> setvalue!(r, convert(K, v)),
    [r],
)

Base.convert(::Type{MayBeReactive{T}}, r::AbstractReactive{K}) where {T, K} = Reactor{T}(
    () -> convert(T, getvalue(r)),
    (v::T) -> setvalue!(r, convert(K, v)),
    [r],
)

function resolve(::Type{T}, r::MayBeReactive) where {T}
    return if r isa T
        r
    else
        getvalue(r)
    end
end
