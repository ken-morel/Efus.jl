# Efus expressions

- [`IonicEfus.Ast.Expression`](@ref)
- [`IonicEfus.Gen.generate(::IonicEfus.Ast.Expression)`](@ref)

Here we are going to talk about the various
type of expressions that efus allows, those you
can place after the `=` in a component call.

## Julia expressions

- [`IonicEfus.Ast.Julia`]

These are expressions which are directly parsed
and substituted from julia, they are also 
passed through [`IonicEfus.Ionic.transcribe`]
so you can use ionic in them, they thus provide
most of julia syntax features, they include.

### Strings

You can type strings like `"ama"` and even
substitute variables like `"ama $foo"`(ionic supported).

!!! !WARNING
    Placing strings in expressions in strings substitutions
    are not supported, thus you may not use
    something like `"foo $(val' * "s")"`, since efus
    will break parsing at the '"' quote.

### Numeric

Efus allow typing numeric values, these include simple 
numbers like `13` to complex values like `13e5px`, where
px which is a multiplication, other examples include.

- `1_102.182`
- `17.5px`
- `5e-5`
- ...

### Symbols

They are like julia symbols.

- `:foo` -> a symbol


### Julia expressions

This are plain julia expressions, contained in (),
and expressions following `if`, `for ... in`, `elseif`
before the newline and type assertions, efus takes
note of the count of brackets(ignoring those in strings)
to permit you to use multiline expressions. When
you use brackets, the whole expressions, including 
the brackets are passed to julia, so you can type tuples
without double quoting:

- `(c = 4; c * 5)` -> a block
- `(1, 2)` ->  a tuple
- `(...)` -> almost any valid julia.

Single identifiers(and true, false, nothing, ...)
may not be braced.

- `name`
- `name'`

Please, also take note of `Reactors`, which have some
similar syntax but I'll explain later.

## Reactors

- [`IonicEfus.Reactor`](@ref)
- [`IonicEfus.Ast.Reactor`](@ref)
- [`IonicEfus.Gen.generate(::IonicEfus.Ast.Reactor)`](@ref)

Reactor syntax permit you to define computed
reactive values. They are defined as julia expressions
with braces, and a type assertion which specifies the
type contained by the reactor but the value returned
by the expression will always be casted to the reactor 
type.

- `(a' / b')::Float32`

## Lists, Vect or Vectors

- [`IonicEfus.Ast.Vect`](@ref)
- [`IonicEfus.Gen.generate(::IonicEfus.Ast.Vect)`]

efus permits you to type expressions in `[]` quotes
with vector syntax, you can nest, vect definitions,
use newlines, ...

- `[1, [1, 2], :ama]`


