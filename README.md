# Efus

Efus comes from a word meaning component for that's the aim, efus provides
templates and types for building backends and templates for components to design
user interfaces.

To that effect efus provides a syntax called `efus` which is meant to help
by providing a simple way to define templates, components and their properties.
But efus does not provide them, efus just provides the syntax to define them.

```swift
using Gtak
# An example of usage with components from Gtak.jl
Window title="Sample window with" box=vertical
  Label text="Do you want to eat Ndole?"
  Box orient=horizontal
    Button text="Yes" action=(() -> println("Ndole is delicious!"))
    Button text="No" action=(() -> println("You are missing out!"))
```

Efus code actualy translate to a list of instructions that are then executed one
by one: efus does not define how a ui will look like but instead lists steps to
create it. It also provides a set of ui related types for representing geometry,
julia literals, ...

## templates

Efus provides means to create Templates each with their own properties, and
backends can use these templates to create components.
Templates are like classes which define the set of methods and attribute
of their instances.

```julia
# Ectract from Gtak.jl
GtakBox = Template(
  :Box,
  GtakBoxBackend(),
  [
    :orient! => EOrient,
  ]
)
```

## components

Templates can then be instantiate to create components, components are what the
user uses to interact with the application, they hold information related to
state, arguments.

## mounts

A mount is the way efus offers the backend to store the backend related data
asscoiated with a widget, a component can be mounted and unmounted, which
should not change the mount since the component are the one to hold the widget
state.

## efus code

Just like said earlier, efus is a set of instructions for creating and
affiliating components, the instructions may be template instantiations as
well as if statements, ~loops, and other control flow structures~.
Extract from Gtak examples

```julia
using Gtak

function clicked(comp)
  comp[:text] *= ">>"
end

page = efuseval"""
using Gtak

Window title="Hello world" box=vertical
  Label&label text="Welcome to todo app!"
  Box orient=horizontal
    Label text="Enter your todo here"
    Button text="I love A level" onclick=(clicked)
  Box orient=vertical

"""Main

if iserror(page)
  display(page)
  exit(1)
end
window = mount!(page)
```
