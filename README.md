# Efus.jl

> [!WARNING]
> This is still in very very active development.

Efus.jl julia module combines a language parser for `efus` language
(created with the module), a few types and abit more to help you create ui
components in julia using an easy to read language which converts to julia code at
macro expansion.

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
    Frame padding=3x3
      Scale size=20x20 value=4 val=(hello' * "friend") args...
    """, true
) |> println

Ast.Block
  ComponentCall(:Frame)
    Arguments:
      Argument(:padding, value=Main.Efus.Size{Int64})
    Children:
      ComponentCall(:Scale)
        Arguments:
          Argument(:size, value=Main.Efus.Size{Int64})
          Argument(:value, value=4)
          Argument(:val, value=hello' * "friend")
        Splats:
          Splat(:args)
Frame(padding = Main.Efus.Size{Int64}(3, 3, nothing), children =
[Scale(args..., size = Main.Efus.Size{Int64}(20, 20, nothing),
value = 4, val = (Reactor){Any}((()->getvalue(hello) * "friend"),
nothing, [hello]))])
```

Basicly just function calls, so you can easily get on with it for
even more.

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

### Efus values

Efus accepts few kind of values

#### Julia literals

```julia
Button text="Hello" symbol=:center callback=print c=4.5
```

Supports Int64, Float64, Symbols, Strings.

#### Julia expressions

As you've seen earlier efus permits you to write julia
exporessions in () quotes. or simply to end a variable name
with a `'`. The Reactivity Sigil!(I learnt a new word!).
Efus checks, if it sees such a sigil in the code, it
generates a Reactor(), with no getter and the name
as dependency, but if it finds none, it simply
quotes the expression in the generated code.

```julia
Button code=("Constant expression") name=reactive' text=("A reactor " * here')
```

#### Abit more

- **Efus.Size**: writes like `12x45`, or `585.48x485.5px`. The object
  has .x, .y and .unit attributes.
- **Efus.Geometry**: This is abit more than size. It constitutes
  of parts like `183x38.45px`, linked via `+` or `-`.
  e.g `+12px+23px+34x48px`. The structure has .signs, .parts, and .units
  array which store vectors of characters, lists of numbers or symbols|nothing respectively.

Well, that's what it is to try to have a handwritten documentation I guess. I'm really
bad at it :-(. Whatever, hope you have a fun time!
