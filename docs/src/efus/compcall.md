# Component calls

- [`IonicEfus.Ast.ComponentCall`](@ref)
- [`IonicEfus.Gen.generate(::IonicEfus.Ast.ComponentCall)`](@ref)

The component call is the most basic and what
really builds the ui, a component call
is simply a statement where you invoke
a function, or constructor which returns
a component or list of components.

## Syntax

```julia
Label text="hello" style:color="blue" args...
____   _________    ________________   ______
  1        2               3              4
```

### `(1)` Component name 

This componentname or component constructor name
is the simple name of the function which
will be called, IonicEfus supports julia names
like `Label!`.
Since it simply calls a function you may place
almost anything there, even `print`.
A component call may figure and must atleast have
a component constructor name.

### `(2)` key=value arguments and `(3)`

The key is any valid julia identifier, and the value
is any accepted [Evus value](./values.md).

Another variation is the `(3)` case, in that case,
`IonicEfus.Gen.generate` converts the statement to a dict construction,
e.g in that case, we may have:

```julia
style = Dict(
  :color => "blue",
)
```

This is meant just to help users easily specify things
like styles with `style:` and things like callbacks
with `on:`.

See [The style guide](../styleguide.md).

### `(4)` Splats

Splats translate into actual keyword argument splats.


## Creating a component

[The Component](../guide/component.md)
