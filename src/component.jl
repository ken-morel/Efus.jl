export AbstractComponent, mount!, unmount!, remount!
export update!, render, getchildren, getparent
export isdirty, dirty!

"""
    abstract type AbstractComponent end

The abstract type all efus components must subtype.
e.g

```julia
Base.@kwdef struct MyComponent <: AbstractComponent
    prop1::String = "default"
    prop2::Int = 0
    parent::Union{AbstractComponent, Nothing} = nothing
    dirty::Bool = true
    children::Vector{AbstractComponent} = AbstractComponent[]
end
```
"""
abstract type AbstractComponent end

function mount! end
function unmount! end
function remount! end
function update! end
function render end
function getchildren end
function getparent end
function isdirty end
function dirty! end


"""
    function cleanchildren(children::Vector)::Vector{AbstractComponent}

Receives a vector where it filters out all non-`AbstractComponent` entries,
and splats any nested vectors, returning a flat vector of `AbstractComponent`s.

This function is used by generated code on the children of a componentcall, 
when it is noticed they contain a codeblock or condition.
"""
function cleanchildren(children::Vector)::Vector{AbstractComponent}
    children isa Vector{<:AbstractComponent} && return children
    final = AbstractComponent[]
    for child in children
        if child isa AbstractComponent
            push!(final, child)
        elseif child isa AbstractVector
            append!(final, cleanchildren(child))
        elseif !isnothing(child)
            error(
                "Component was passed an unexpected child of type $(typeof(child)): $child. " *
                    "Make sure it either returns a component, a vector of components, or nothing."
            )

        end
    end
    return final
end
