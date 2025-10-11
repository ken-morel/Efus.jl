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
