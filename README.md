# Efus.jl

[![CI](https://github.com/ken-morel/Efus.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/ken-morel/Efus.jl/actions/workflows/CI.yml)

> [!NOTE]
> This is still in very active development. It remains usable, though not tested enough to be proven stable yet.

Efus.jl julia module combines a language parser for `efus` language
(created with the module), a few types and abit more to help you create ui
components in julia using an easy to read language which converts to julia code at
macro expansion.

For a usage example, see the [Attrape.jl](https://github.com/ken-morel/Attrape.jl)

## Efus language & parser

Efus is a pug-like language, with indentation based hierarchy and made to
let you know what is done(so you can easily debug your code).
The parser itself is stored in the `Efus.Parser.EfusParser` structure which
has a simple `parse!` method which returns either an `Efus.Ast.Block`
or `Efus.Parser.AbstractParseError`.

```julia
using Efus
file = "code.efus"
ast = try_parse!(EfusParser(read(file, String), file))

```

## The julia code generator

Under the `Efus.Gen` module live few simple methods which convert Ast
objects to julia expressions.

```julia
using Efus

code = Efus.Gen.generate(ast)
```

There's also a `Efus.codegen_string` to help you view the generate
code. It has an optional second boolean argument to also show
ast(prints directly, does not return a string).

```julia
Efus.codegen_string(
    """
    Frame padding=(3, 3)
      Scale size=(20, 20) value=4 val=(hello' * "friend") args...
    """, true
) |> println

Ast.Block
  ComponentCall(:Frame)
    Arguments:
      Argument name=:padding
        Value:
          Vect
            Numeric val=3
            Numeric val=3
    Children:
      ComponentCall(:Scale)
        Arguments:
          Argument name=:size
            Value:
              Vect
                Numeric val=20
                Numeric val=20
          Argument name=:value
            Value:
              Numeric val=4
          Argument name=:val
            Value:
              Fuss expr=(hello' * "friend")
        Splats:
          Splat name=:args
Frame(padding = (3, 3), children =
[Scale(args..., size = (20, 20),
value = 4, val = (Reactor){Any}((()->getvalue(hello) * "friend"),
nothing, [hello]))])
```

Basicly just function calls, so you can easily get on with it for
even more.

## Control flow

efus suports if and for for now, each with the usual julia syntax.
(for loop even supports both in and =).

```julia
Frame
  if foobar !== true
    Label text="hello world"
    for (name, for) = foes
      Plaintain name=name
    else
      Egg
    end
  end
```

The for generates a list comprehension and an if statement
to check if the iterable is `empty`. And some more code
flattens the children list before passing it to the parent.

### Generator macros

To get that done more easily, there are two macros, `@efus_str` and
`@efus_build_str`, where the first returns a closure.

## Components

The main aim of efus is to be used with components in a lifecycle
constituting of:

- **creation**: when you call the constructor. Efus gives room
  for only keyword arguments, making `Base.@kwdef` very usefull.
  I prefer that nothing should be done here except initial initialization.

  ```julia
  @Base.@kwdef mutable struct Button
    text::MayBeReactive{String} = "Button" #a.k.a String, or reactive
    onclick::Function
    children::Vector{AbstractComponent} = Button[] # just to show
  end
  ```

  This can then be easily used.

- **mounting**: Mounting is done via the `mount!` method.
  Efus is not responsible for implementing this, on to you.
  This uses the state of the component, catalyzes to reactants
  and create widgets or so.
- **unmounting**: This is just the opposite. Done with `unnmount!`.
- **updating**: This is to update the component when
  one of it's reactive attributes changed.

## Composing components

You can for that, define a function, which takes keyword
arguments and return a component, then call it from
efus code, as such the function will not count in the
component tree, but it works.
If you need your composite component to accept children,
simply accept a `children::Vector{<:AbstractComponent} = []`.
and pass it down to something else.

You need to specify a default value, since if no children
were passed, efus does not pass a children argument,
but that's also what permits you to pass those
children to another component, let say `Box children=children`.

## Reactivity

Efus wants that the backend should be responsible of ui updates.
As such, when a reactive's value changes, it notifies directly
all it's catalysts, it is their responsibility then to
handle that without impacting runtime, like batching them
for a future update. In case you did not catch all the grammar,
here's some explanation:

### Reactants

Reactants as all other reactives are subtypes of
`AbstractReactive{T}`, where T is the type of the contained
value. They store a value, and notifies reacting
catalysts when it is changed via `setvalue!`. It's
value can be gotten via `getvalue!`(or simply getting
or setting the .value attribute).
Reactants are abit strict in typing, and we advice to only
use concrete types when operating with them.

### Catalysts

To reactants, are catalysts, catalysts are the objects
which permits you to get updated of reactants changes.
They support a few methods:

- `catalyze!(catalyst, reactant, callback)`: To trigger
  a callback when reactant value changes. (start
  a `Reaction`).
- `denature!(catalyst)`: To inhibit all ungoing
  `Reactions`.

### Reactions

This is what is returned from `catalyze!` call, it is
stored in an internal `.reactions` vector and
stores every reactant, catalyst, callback. You
can directly `inhibit!` them.

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

A reactor is an `AbstractReactive{T}` subtype which aim
to permit you create reactive objects whose value are
computer or set via methods to other reactants or not.
Efus uses that internally if you create a reactive
expression like `("I love" + react')`.

```
c = 5
r = Reactor{Int}(
  () -> c,
  (x::Int) -> c = x,
)
#or Reactor(T, get, set)
```

It also allows a last optional argument which is a list
of other AbstractReactive objects(even other reactors) it depends on,
and will sibscribe and update when they change.

### Reactive expressions

A reactive expression is that which Efus converts to a Reactor
it is like normal julia code, except that you end
reactor names with a `'` and use them directly, Efus will
then expand to the appropriate `getvalue` call and create
a reactor with it as dependency.

```julia
(hello' * "friend")
# Becomes
Reactor){Any}((()->getvalue(hello) * "friend"), nothing, [hello])
```

## Ionic Syntax and Utilities

Efus provides a powerful reactive programming model, centered around the 'ionic' syntax (ending a variable name with `'`) and a set of utility macros to simplify working with reactive values.

### Ionic Syntax (`'`)

The apostrophe (`'`) at the end of a variable name signifies an "ionic expression." This indicates that the variable is a reactive value (an `AbstractReactive` subtype like `Reactant` or `Reactor`), and Efus will automatically expand it to `getvalue(variable)` when used in an expression, or `setvalue!(variable, ...)` when used in an assignment.

```julia
# In Efus code:
Label text=(my_reactive_var' * " is active!")

# Expands to something like:
Label(text = getvalue(my_reactive_var) * " is active!")
```

### `@ionic` Macro

The `@ionic` macro is a low-level utility that translates Efus's ionic syntax into standard Julia code, specifically `getvalue` and `setvalue!` calls. It's primarily used internally by other macros but can be useful for debugging or when you need precise control over the translation.

```julia
using Efus
my_reactant = Efus.Reactant(10)

# Translates the ionic expression into Julia code
julia_expr = @macroexpand Efus.@ionic my_reactant' * 2
# julia_expr will be something like: :(Efus.getvalue(my_reactant) * 2)

result = @ionic my_reactant' * 2
@test result == 20

@ionic my_reactant' = 50
@test Efus.getvalue(my_reactant) == 50
```

### `@radical` Macro

The `@radical` macro is designed to create a piece of Julia code that automatically re-evaluates whenever any of its reactive dependencies change. It's conceptually similar to reactive statements in frameworks like Svelte (e.g., `$: {}` or `$effect`). The primary goal is the side-effect of re-evaluation, making it ideal for triggering updates, logging, or performing computations that need to stay synchronized with reactive state.

Internally, `@radical` creates an *eagerly evaluated* `Reactor`. While it returns this `Reactor` object, its main purpose is to establish the reactive link that drives the re-evaluation.

```julia
using Efus
a = Efus.Reactant(1)
b = Efus.Reactant(2)

# This block will re-run whenever `a` or `b` changes
my_effect = @radical begin
    sum_val = a' + b'
    println("Current sum: ", sum_val)
    sum_val # The value of the radical itself
end

# Initial run
# Output: Current sum: 3
@test Efus.getvalue(my_effect) == 3

Efus.setvalue!(a, 10)
# Output: Current sum: 12 (re-evaluated automatically)
@test Efus.getvalue(my_effect) == 12

Efus.setvalue!(b, 20)
# Output: Current sum: 30 (re-evaluated automatically)
@test Efus.getvalue(my_effect) == 30
```

### `@reactor` Macro

The `@reactor` macro provides a convenient and type-inferring way to create a `Reactor` object. A `Reactor` is a reactive value whose content is derived from other reactive (or non-reactive) sources. By default, `@reactor` creates a *lazily evaluated* `Reactor`, meaning its value is only re-computed when explicitly requested via `getvalue` after its dependencies have changed.

This macro simplifies the creation of derived reactive state, allowing you to define complex reactive computations with a clean syntax.

```julia
using Efus
x = Efus.Reactant(5)
y = Efus.Reactant(10)

# Create a lazy reactor that computes x' * y'
product_reactor = @reactor x' * y'

@test product_reactor isa Efus.Reactor{Int}
@test Efus.getvalue(product_reactor) == 50

Efus.setvalue!(x, 2)
# The reactor is now fouled, but its value hasn't updated yet
@test Efus.isfouled(product_reactor)
@test product_reactor.value == 50 # Still the old value

@test Efus.getvalue(product_reactor) == 20 # Forces re-computation
@test !Efus.isfouled(product_reactor)

# You can also provide a setter function
counter = Efus.Reactant(0)
increment_reactor = @reactor counter' + 1 (val -> Efus.setvalue!(counter, val - 1))

@test Efus.getvalue(increment_reactor) == 1
Efus.setvalue!(increment_reactor, 5)
@test Efus.getvalue(counter) == 4
@test Efus.getvalue(increment_reactor) == 5
```

Well, that's what it is to try to have a handwritten documentation I guess. I'm really
bad at it :-(. Whatever, hope you have a fun time!
