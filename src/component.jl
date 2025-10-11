export Components
export Component, mount!, unmount!, remount!
export update!, render, getchildren, getparent
export isdirty, dirty!

"""
    abstract type Component end

The abstract type all efus components must subtype.
e.g

```julia
Base.@kwdef struct MyComponent <: Component
    prop1::String = "default"
    prop2::Int = 0
    parent::Union{Component, Nothing} = nothing
    dirty::Bool = true
    children::Vector{Component} = Component[]
end
```
"""
abstract type Component end

"""
    const Components = Vector{<:Component}

Just to help you receive component lists.
"""
const Components = Vector{<:Component}


"""
    mount!(c::Component, [parent::Component];args...)

Mount `c` in it's `parent`, create
the subscriptions, backend data and more.
You may return the associated backend data.

The default mount! throws an exception.
"""
mount!(
    ::C, p::Union{Component, Nothing} = nothing;
    args...
) where {C <: Component} = error("Mounting not supported by $C")

"""
    unmount!(::C) where {C <: Component}

Unassociate any data and destroy what
was creted durint [`mount!`](@ref).

The default implementation throws an exception.
"""
unmount!(::C) where {C <: Component} = error("Unmounting not supported by $C")

"""
    remount!(::Component;args...)

Remounts the component, efus 
default behaviour is to successively call
[`unmount!`](@ref) and [`mount!`](@ref).
It may return the associated data durint
mount!.

The default implementation throws an exception
"""
function remount!(c::C; args...) where {C <: Component}
    throw("remounting not supported by $C")
end

"""
    update!(c::Component)

Update the data know as [`dirty!`](@ref),
when the component is mounted.

The default implementation throws an exception.
"""
function update!(c::C; args...) where {C <: Component}
    error("Updating not supported by $C")
end

"""
    getchildren(c::Component)::Union{Components, Nothing}

Get the childrens of the component. Or return nothing if
found.

The default implementation checks for a `.children`
atttribute of type [`Components`](@ref).
"""
function getchildren(c::Component)::Union{Components, Nothing}
    return if hasproperty(c, :children) && c.children isa Components
        c.children
    end
end

"""
    getparent(c::Component)::Union{Component, Nothing}

Get the parent of component c.

The default implementation checks for a `.parent`
property of type [`Component`](@ref).
"""
function getparent(c::Component)::Union{Component, Nothing}
    return if hasproperty(c, :parent) && c.parent isa Component
        c.parent
    end
end

"""
    isdirty(::Component)::Bool

Get if any component field was marked as
dirty.

The default implementation throws an exception.
"""
function isdirty(::C)::Bool where {C <: Component}
    error("Dirty not supported by $C")
end

"""
    getdirty(::Component)::Set{Symbol}

Get the component fields which were marked as dirty.

The default implementation throws an exception.
"""
function getdirty(::C)::Set{Symbol} where {C <: Component}
    error("Dirty not supported by $C")
end

"""
    params(::Type{C})::Set{Symbol} where {C <: Component}
    params(::C)::Set{Symbol} where {C <: Component}

Get the parameters supported by components of
type C.

The default implementation throws an exception.
"""
function params(::Type{C})::Set{Symbol} where {C <: Component}
    error("Params not implemented for $C")
end
params(::C) where {C <: Component} = params(C)

"""
    dirty!(c::Component, key::Symbol, value)
    dirty!(c::Component, k::Key)

Mark the specified key as dirty, after setting
the value.

The default dirty!(c, k, v) sets c.(k) then 
calls dirty!(c, k)
"""
function dirty!(c::Component, key::Symbol, value)
    c.key = value
    return dirty!(c, key)
end


"""
    function cleanchildren(children::Vector)::Vector{Component}

Receives a vector where it filters out all non-`Component` entries,
and splats any nested vectors, returning a flat vector of `Component`s.

This function is used by generated code on the children of a componentcall, 
when it is noticed they contain a codeblock or condition.
"""
function cleanchildren(children::Vector)::Components
    children isa Components && return children
    final::Vector{Component} = Component[]
    for child in children
        if child isa Component
            push!(final, child)
        elseif child isa AbstractVector
            append!(final, cleanchildren(child))
        elseif !isnothing(child)
            error(
                "Component or code block was passed a child of unexpected type $(typeof(child)): $child. " *
                    "If you use a custom function or julia expression, make sure it either " *
                    " returns a component, a vector of components, or nothing."
            )

        end
    end
    return final
end
