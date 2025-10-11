# The component

We are here going to study how to define
a component structure, and about
the component life cycle.

## Declaring the component

A component constructor can be a
function returning a component, it accepts
**only** keyword arguments. An example
component would be:

```julia
struct Label <: IonicEfus.Component
    foo::Bar = folk
    foos::Bars = foo + 1
    <...>
end
```
This way you can easily specify defaults,
types and more as needed.
Usually you will have:

- **attibutes**: Attributes received from the
  caller, they may provide defaults, types, ...
- **backend data**: Those maybe things used
  by the component like actual widgets.

In this example we are going to take
a minimal example from Gtak.jl

```julia
Base.@kwdef mutable struct Button <: GtakWidgetComponent
    text::MayBeReactive{String}                      | 1
    onclick::Union{Function, Nothing} = nothing      |

    children::Components = []                        | 2

    widget::Union{GtkButton, Nothing} = nothing      | 3
    label::Union{GtkLabel, Nothing} = nothing        |
    parent::Union{GtakComponent, Nothing} = nothing  |


    dirty::Set{Symbol} = Set()                       | 4

    const catalyst::Catalyst = Catalyst()            | 5
end
IonicEfus.params(::Type{Button}) = [:text, :onclick]

```

1. **Attributes**:
   These are attributes passed by the caller
2. **Children**:
   If the component receives children, efus.jl will
   pass to it an array of type [`IonicEfus.Components`](@ref)
   simply an alias to `Vector{<:Component}`.

   This will be ignored if it received no child,
   and you may also use `children` as keyword argument.

   Efus treats the array
   by cleaning it with [`IonicEfus.cleanchildren`](@ref)
   which removes nothings, splats arrays returned by ifs,
   though reduces performance.
3. **Backend data**:
   This is data specific to the backend, for the component
   to stay reusable, they are set on mounting and unset
   when the component is unmounted.
4. **Dirt keeper**:
   A little array which keeps parameters which need
   to be updated because they have changed.

5. **Catalyst**:
   A catalyst for managing subscriptions, since
   they can be subscribed and [`denature!`](@ref)'d,
   they may be conserved.



## mounting

- [`IonicEfus.mount!`](@ref)

A component is meant to be a reusable blue print.
During mounting the component is initialized,
subscriptions are made, and the parent is set.

```julia
function IonicEfus.mount!(b::Button, parent::GtakComponent)
    b.parent = parent               # Associating the parent
    b.widget = GtkButton()                           # Create backend widgets
    b.widget[] = b.label = GtkLabel(resolve(b.text)) #
    # for child in b.children             # if it has children
    #     push!(b.widget, mount!(chlid))  #
    # end                                 #
    signal_connect(b.widget, :clicked) do _     # Connect signals(backend specific)
        if !isnothing(b.onclick)                #
            schedule(b, Sched.CallBackCall() do #
                b.onclick()                     #
            end)                                #
        end                                     #
        return                                  #
    end                                         #
    if b.text isa AbstractReactive
        catalyze!(b.catalyst, b.text) do _ # setup subscriptions
            dirty!(b, :text)               #
            schedule(                      #
                b,                         #
                Sched.ComponentUpdate(b),  #
            )                              #
        end                                #
    end
    return b.widget
end
```

[`IonicEfus.resolve`](@ref) helps you get the value of
[`IonicEfus.MayBeReactive`](@ref) objects.

When the text get's updated from the reactive instance,
you may add an entry to `dirty!` instead of updating
directly, and then schedule a ui update.

## Updating

- [`IonicEfus.update!`](@ref)

During the update, you can update all the
parameters you know to have passed through dirty.
If you use the scheduer as above, or update
in threads you may obviously need to hold a lock
or simply wrap the dirty in a `Base.Lockable`.

```julia
function IonicEfus.update!(c::Button)
    ...
    empty!(c.dirty)
    return
end
```

## Unmounting

- [`IonicEfus.unmount!`](@ref)

Here we may dissociate and destroy any data
associated during mount, denature catalysts,
to obtain back a clean component.

```julia
function IonicEfus.unmount!(c::Button)
    children = getchildren(c)
    if !isnothing(children)
        foreach(unmount!, c.children)
    end
    destroywidget(c.widget)
    c.parent = nothing
    denature!(c.catalyst)
    return
end
```

## Full interfaces

To provide the full api you may provide a few methods
implementations for the component:

- **Important:**

  - [`IonicEfus.params`](@ref)
  - [`IonicEfus.mount!`](@ref)
  - [`IonicEfus.unmount!`](@ref)

- **Adviced:**

  - [`IonicEfus.getparent`](@ref)
  - [`IonicEfus.getchildren`](@ref)
  - [`IonicEfus.remount!`](@ref)
  - [`IonicEfus.update!`](@ref)

- If you want to implement the dirty mechanism

  - [`IonicEfus.dirty!`](@ref)
  - [`IonicEfus.isdirty`](@ref)
  - [`IonicEfus.getdirty`](@ref)


