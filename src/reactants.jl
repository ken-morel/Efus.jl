using FunctionWrappers

abstract type AbstractReactive{T} end

export Reactant, Catalyst, Reaction, AbstractReaction
export getvalue, setvalue!, catalyze!, inhibit!, denature!
export resolve, MayBeReactive
export AbstractReactive, Reactor


abstract type AbstractReaction{T} end

struct Catalyst
    reactions::Vector{AbstractReaction}

    Catalyst() = new([])
end


const REACTOR_SETTER{T} = FunctionWrapper{Any, Tuple{T}}
const REACTOR_GETTER{T} = FunctionWrapper{T, Tuple{}}

mutable struct Reactor{T} <: AbstractReactive{T}
    getter::REACTOR_GETTER{T}
    setter::Union{REACTOR_SETTER{T}, Nothing}
    const content::Vector{AbstractReactive}
    const reactions::Vector{AbstractReaction{T}}
    const catalyst::Catalyst
    fouled::Bool
    value::Union{T, Nil}

    Reactor{T}(getter::REACTOR_GETTER{T}, setter::Union{REACTOR_SETTER{T}, Nothing}) where {T} = new{T}(
        getter,
        setter,
        [],
        [],
        Catalyst(),
        true,
        Nil(),
    )
    function Reactor{T}(getter::Function, setter::Union{Function, Nothing}, content::Vector{<:AbstractReactive})::Reactor{T} where {T}
        getter = REACTOR_GETTER{T}(getter)
        setter = if !isnothing(setter)
            REACTOR_SETTER{T}(setter)
        end
        r = Reactor{T}(getter, setter)
        callback = (_) -> if !r.fouled
            r.fouled = true
            notify!(r)
        end

        for reactant in content
            push!(r.content, reactant)
            catalyze!(r.catalyst, reactant, callback)
        end
        return r
    end
    Reactor(::Type{T}, getter::Function, setter::Union{Function, Nothing}, content::Vector{<:AbstractReactive}) where {T} = Reactor{T}(getter, setter, content)
end


mutable struct Reactant{T} <: AbstractReactive{T}
    value::T
    reactions::Vector{AbstractReaction{T}}

    Reactant{T}(value::T) where {T} = new{T}(value, [])
    Reactant(value::T) where {T} = new{T}(value, [])
end


struct Reaction{T} <: AbstractReaction{T}
    reactant::AbstractReactive{T}
    catalyst::Catalyst
    callback::FunctionWrapper{Nothing, Tuple{T}}
end

"""
    getvalue(r::AbstractReactive{T})

Returns the current value of the Reactant.
"""
function getvalue(r::AbstractReactive{T})::T where {T}
    return r.value
end

"""
    setvalue!(r::Reactant{T}, new_value::T) where T

Sets a new value for the Reactant and triggers all associated reactions.
"""
function setvalue!(r::Reactant{T}, new_value::T) where {T}
    r.value = new_value
    for reaction in r.reactions
        reaction.callback(new_value)
    end
    return r
end

"""
    catalyze!(c::Catalyst, r::AbstractReactive{T}, callback::Function)::Reaction{T} where T

Creates and registers a new Reaction.

This is the core subscription function. It links a Reactant to a Catalyst
and specifies the callback to execute when the Reactant's value changes.
"""
function catalyze!(c::Catalyst, r::AbstractReactive{T}, callback::Function)::Reaction{T} where {T}
    wrapped_callback = FunctionWrapper{Nothing, Tuple{T}}(callback)

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


isfouled(r::Reactor) = r.fouled

function setvalue!(r::Reactor{T}, val::T) where {T}
    return isnothing(r.setter) || r.setter(val)
end
function notify!(r::Reactor)
    for reaction in r.reactions
        reaction.callback(r.value)
    end
    return
end
function unfoul!(r::Reactor{T})::T where {T}
    r.value = r.getter()
    r.fouled = false
    return r.value
end
function getvalue(r::Reactor{T})::Union{T, Nil} where {T}
    return if r.fouled
        unfoul!(r)
    else
        r.value
    end
end


const MayBeReactive{T} = Union{T, AbstractReactive{T}}

function resolve(r::MayBeReactive{T})::T where {T}
    if r isa AbstractReactive
        return getvalue(r)
    else
        return r
    end
end
