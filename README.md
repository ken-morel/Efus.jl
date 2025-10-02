# IonicEfus.jl

[![CI](https://github.com/ken-morel/IonicEfus.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/ken-morel/IonicEfus.jl/actions/workflows/CI.yml)

> [!NOTE]
> This is not very stable, but it works.

IonicEfus.jl is a Julia module that combines a language parser for the `efus` language, a converter for [ionic], and a bit more to help you build component-based UIs using an easy-to-read language with concepts idiomatic to Julia.

For a usage example, see the [Gtak.jl](https://github.com/ken-morel/Gtak.jl).

## Efus language & parser

Efus is a pug-like language, with indentation based hierarchy and made to let you know what is done (so you can easily debug your code). The parser itself is stored in the `IonicEfus.Parser.EfusParser` structure which has a simple `parse!` method which returns either an `IonicEfus.Ast.Block` or `IonicEfus.Parser.AbstractParseError`.

```julia
using IonicEfus
file = "code.efus"
ast = try_parse(read(file, String), file)
```

## The julia code generator

Under the `IonicEfus.Gen` module live few simple methods which convert Ast objects to julia expressions.

```julia
using IonicEfus

code = IonicEfus.Gen.generate(ast)
```

There's also a `IonicEfus.codegen_string` to help you view the generated code. It has an optional second boolean argument to also show the ast (prints directly, does not return a string).

```julia
IonicEfus.codegen_string(
    """
    Frame padding=(3, 3)
      Scale size=(20, 20) value=4 val=(hello' * "friend") args...
    """
) |> println

Frame(padding = (3, 3), children =
[Scale(args..., size = (20, 20),
value = 4, val = (Reactor){Any}((()->getvalue(hello) * "friend"),
nothing, [hello]))])
```

Basically just function calls, so you can easily get on with it for even more.

## Control flow

efus suports if and for control flow structures, each with meant to capture the most of the usual julia syntax. For expressions, efus allows any [ionic] expression, which will be translated to julia.

```julia
Frame
  if foobar' !== true
    Label text="hello world"
    for (name, for) in foes
      Plaintain name=name
    else
      Egg
    end
  end
```

The for generates a list comprehension and an if statement to check if the iterable is `empty` when given an else block. And `IonicEfus.cleanchildren` is called to remove any `nothing` and flattens the children list before passing it to the parent.

### Generator macros

To generate code, use the `@efus_str`.

## Components

The main aim of efus is to be used with components in a lifecycle constituting of:

- **creation**: when you call the constructor. Efus gives room for only keyword arguments, making `Base.@kwdef` very usefull. I prefer that nothing should be done here except initial initialization.

  ```julia
  @Base.@kwdef mutable struct Button
    text::MayBeReactive{String} = "Button" #a.k.a String, or reactive
    onclick::Function
    children::Vector{AbstractComponent} = Button[] # just to show
  end
  ```

  This can then be easily used. A standard rule I would like to impose, is that just initialized components should store only parameters data, any other thing, like subscriptions, parents and others should be passed during mounting, and removed when unmounting. To be sure components are fully serialisable, remountable copyable and reusable units.

- **mounting**: Mounting is done via the `mount!` method. IonicEfus is not responsible for implementing this, on to you. This uses the state of the component, catalyzes to reactants and create widgets or so.
- **unmounting**: This is just the opposite. Done with `unnmount!`.
- **updating**: This is to update the component when one of it's reactive attributes changed. An option, could be to check for an internal list of dirty attributes, and only update those.

## Composing components

One good things with components, is that they can be composed. All you have to do, is to create a function! You can also add a children keyword parameter to support children.

## Reactivity

IonicEfus wants that the backend should be responsible of ui updates. As such, when a reactive's value changes, it notifies directly all it's catalysts, it is their responsibility then to handle that without impacting runtime, like batching them for a future update. In case you did not catch all the grammar, here's some explanation:

### Reactants

Reactants as all other reactives are subtypes of `AbstractReactive{T}`, where T is the type of the contained value. They store a value, and notifies reacting catalysts when it is changed via `setvalue!`. It's value can be gotten via `getvalue`(or simply getting or setting the .value attribute). Reactants are abit strict in typing, and we advice to only use concrete types when operating with them.

> [!TIP]
> You can always create a custom reactive type by subtyping `AbstractReactive{T}` and implementing.

> You can also use `MayBeReactive{T}` for you know what.

### Catalysts

To reactants, are catalysts, catalysts are the objects which permits you to get updated of reactants changes. They support a few methods:

- `catalyze!(catalyst, reactant, callback)`: To trigger a callback when reactant value changes. (start a `Reaction`).
- `denature!(catalyst)`: To inhibit all ongoing `Reactions`.

### Reactions

This is what is returned from `catalyze!` call, it is stored in an internal `.reactions` vector and stores every reactant, catalyst, callback. You can directly `inhibit!` them.

```julia
reactant = Reactant{Float32}(1)
reaction = catalyze!(Catalyst(), reactant) do value
  print(value)
end
inhibit!(reaction)
# OR
denature!(catalyst)
```

### Reactors

A reactor is an `AbstractReactive{T}` subtype which aim to permit you create reactive objects whose value are computer or set via methods to other reactants or not. IonicEfus uses that internally if you create an [ionic] expression like `("I love" + react')`.

```julia
c = 5
r = Reactor{Int}(
  () -> c,
  (x::Int) -> c = x,
)
#or Reactor(T, get, set)
```

It also allows a last optional argument which is a list of other AbstractReactive objects(even other reactors) it depends on, and will sibscribe and update when they change.

> [!TIP]
> Reactors also allow type inferation, or passing the type as first argument.

## Ionic Syntax and Utilities

IonicEfus adds tools mini language it calls [ionic] it is actually julia code, where you don't have the burden of calling getvalue and setvalue! Again. You can directly assign or use the reactives if you prepend their name or getter with an apostrophe(`'`). Doubling the apostrophe(`''`) escapes it, except in assignments.

```julia
# In Efus code:
Label text=(my_reactive_var' * " is active!")

# Expands to something like:
Label(text = getvalue(my_reactive_var) * " is active!")
```

### `@ionic` Macro

The `@ionic` macro is a low-level utility that translates the [ionic] syntax into standard Julia code, specifically `getvalue` and `setvalue!` calls.

```julia
using IonicEfus
my_reactant = IonicEfus.Reactant(10)

# Translates the ionic expression into Julia code
julia_expr = @macroexpand IonicEfus.@ionic my_reactant' * 2
# julia_expr will be something like: :(IonicEfus.getvalue(my_reactant) * 2)

result = @ionic my_reactant' * 2
@test result == 20

@ionic my_reactant' = 50
@test IonicEfus.getvalue(my_reactant) == 50
```

### `@radical` Macro

The `@radical` macro is designed to create a piece of Julia code that automatically re-evaluates whenever any of its reactive dependencies change. I wanted something like svelte's $effect. which re-runs when a dependency changes. It internally uses a Reactor, but with `eager = true` keword argument to force re-computation when dependency changes(since reactors by default use lazy evaluation).

```julia
using IonicEfus
a = IonicEfus.Reactant(1)
b = IonicEfus.Reactant(2)

# This block will re-run whenever `a` or `b` changes
reactor = @radical begin
    sum_val = a' + b'
    println("Current sum: ", sum_val)
    sum_val # The value of the radical itself
end
```

### `@reactor` Macro

The `@reactor` macro provides a convenient and type-inferring way to create a `Reactor` object. A `Reactor` is a reactive value whose content is derived from other reactive (or non-reactive) sources. By default, `@reactor` creates a _lazily evaluated_ `Reactor`, meaning its value is only re-computed when explicitly requested via `getvalue` after its dependencies have changed.

This macro simplifies the creation of derived reactive state, allowing you to define complex reactive computations with a clean syntax.

```julia
using IonicEfus
x = IonicEfus.Reactant(5)
y = IonicEfus.Reactant(10)

# Create a lazy reactor that computes x' * y'
product_reactor = @reactor x' * y'

@test product_reactor isa IonicEfus.Reactor{Int}
@test IonicEfus.getvalue(product_reactor) == 50

IonicEfus.setvalue!(x, 2)
# The reactor is now fouled, but its value hasn't updated yet
@test IonicEfus.isfouled(product_reactor)
@test product_reactor.value == 50 # Still the old value

@test IonicEfus.getvalue(product_reactor) == 20 # Forces re-computation
@test !IonicEfus.isfouled(product_reactor)

# You can also provide a setter function
counter = IonicEfus.Reactant(0)
increment_reactor = @reactor counter' + 1 (val -> IonicEfus.setvalue!(counter, val - 1))

@test IonicEfus.getvalue(increment_reactor) == 1
IonicEfus.setvalue!(increment_reactor, 5)
@test IonicEfus.getvalue(counter) == 4
@test IonicEfus.getvalue(increment_reactor) == 5
```

Well, that's what it is to try to have a handwritten documentation I guess. I'm really bad at it :-(. Whatever, hope you have a fun time!
