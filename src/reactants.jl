using FunctionWrappers


export Reactant, Catalyst, Reaction, AbstractReaction
export getvalue, setvalue!, catalyze!, inhibit!, denature!
export resolve, MayBeReactive
export AbstractReactive, Reactor


abstract type AbstractReactive{T} end

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


function getvalue(r::AbstractReactive{T})::T where {T}
    return r.value
end


function setvalue!(r::Reactant{T}, new_value::T) where {T}
    r.value = new_value
    for reaction in r.reactions
        reaction.callback(new_value)
    end
    return r
end


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


const MayBeReactive{T} = Union{AbstractReactive{T}, T}

Base.convert(::Type{AbstractReactive{T}}, r::AbstractReactive{Any}) where {T} = Reactor{T}(
    () -> getvalue(r)::T,
    (v::T) -> setvalue!(r, v),
    [r],
)

Base.convert(::Type{AbstractReactive{T}}, r::AbstractReactive) where {T} = Reactor{T}(
    () -> getvalue(r)::T,
    (v::T) -> setvalue!(r, v),
    [r],
)

Base.convert(::Type{MayBeReactive{T}}, r::AbstractReactive{K}) where {T, K} = Reactor{T}(
    () -> getvalue(r)::T,
    (v::T) -> setvalue!(r, v),
    [r],
)

function resolve(::Type{T}, r::MayBeReactive)::T where {T}
    return if r isa T
        r
    else
        getvalue(r)::T
    end
end
