# Ionic

- [`Ionic`](@ref)

Ionic is a little macro utility, which
provides you sugar to set and get the
value of reactive objects.
See [`Ionic.transcribe`](@ref).

Efus defines the [`Efus.@ionic`] macro
which does the transformation.

```julia
using Ionic

a = Reactant(1)
b = Reactant(2)

@ionic a' = b' * 2
```

You can double the `'` quotes to escape
them, and you may not only use `'` on 
variable names but also other kind of expressions.

```julia
@ionic (reactants[currentindex'])' = 4
```
