using FunctionWrappers

export Reactant, Catalyst, Reaction, AbstractReaction
export getvalue, setvalue!, catalyze!, inhibit!, denature!


abstract type AbstractReaction{T} end

struct Catalyst
    reactions::Vector{AbstractReaction}

    Catalyst() = new([])
end

mutable struct Reactant{T}
    value::T
    reactions::Vector{AbstractReaction{T}}

    Reactant(value::T) where {T} = new{T}(value, [])
end

struct Reaction{T} <: AbstractReaction{T}
    reactant::Reactant{T}
    catalyst::Catalyst
    callback::FunctionWrapper{Nothing, Tuple{T}}
end

"""
    getvalue(r::Reactant)

Returns the current value of the Reactant.
"""
getvalue(r::Reactant) = r.value

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
    catalyze!(c::Catalyst, r::Reactant{T}, callback::Function)::Reaction{T} where T

Creates and registers a new Reaction.

This is the core subscription function. It links a Reactant to a Catalyst
and specifies the callback to execute when the Reactant's value changes.
"""
function catalyze!(c::Catalyst, r::Reactant{T}, callback::Function)::Reaction{T} where {T}
    wrapped_callback = FunctionWrapper{Nothing, Tuple{T}}(callback)

    reaction = Reaction{T}(r, c, wrapped_callback)

    push!(c.reactions, reaction)
    push!(r.reactions, reaction)
    return reaction
end


function inhibit!(catalyst::Catalyst, reactant::Reactant, callback::Function)
    reactions_to_inhibit = filter(catalyst.reactions) do sub
        sub.reactant === reactant && sub.callback.func === callback
    end

    for reaction in reactions_to_inhibit
        inhibit!(reaction)
    end
    return
end

function inhibit!(catalyst::Catalyst, reactant::Reactant)
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
