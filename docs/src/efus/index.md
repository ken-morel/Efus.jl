# The efus language

efus is an indentation based, declarative language
which compiles to julia code.
well, efus may look like markup language, but in
fact, efus is a step of instructions for creating
and composing components.

## What's done in the code generation?

The code generation is done into a few simple steps:

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
