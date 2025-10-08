# The efus language

efus is an indentation based, declarative language
which compiles to julia code.
well, efus may look like markup language, but in
fact, efus is a step of instructions for creating
and composing components.

## What's done in the parsing?

The parsing is done into a few simple steps:

`IOBuffer` -> **tokenizing** -> `Channel{Token}` ->
**parsing** -> `Channel{Statement}` -> collect
-> **generation** -> `Expr`

This permits efus to support streaming, though for convenience,
efus provides a [`IonicEfus.parse_efus`](@ref) which does the parsing
and [`IonicEfus.Gen.generate`](@ref) for generating code. But
I'm sure most at times you will just want to use the macros
for doing that for you.

```julia
using IonicEfus

code = "Hello world=4
ast = parse_efus(code)

expr = generate(code)

component = eval(expr)

# OR

component = efus"Hello world=4"

```

## The syntax

I will cover here a few things about efus syntax, ast nodes and
their generated code.

### Component calls

Component calls are I could say the basic and most important
things you are going to use, they may not be only a
call to a component constructor, but to any function, or
a Snippet.
The return type for calling that function should always
be either `nothing`, a `Component` or `Vector{Component}`
efus blocks and parents wrap the children in
[`IonicEfus.cleanchildren`](@ref) which does the splatting
and filtering the nothings, but it throws an exception
if any other kind of value is found.

[`IonicEfus.Ast.ComponentCall`](@ref)
[`IonicEfus.Gen.generate(::IonicEfus.Ast.ComponentCall)`](@ref)
