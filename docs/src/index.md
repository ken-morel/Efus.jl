# IonicEfuss Documentation

```@contents
Pages = ["index.md"]
```

[![CI](https://github.com/ken-morel/IonicEfus.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/ken-morel/IonicEfus.jl/actions/workflows/CI.yml)

> [!NOTE]
> This is not very stable, but it works.

## The language

The efus language is a pug like language with
indent-based heirarchy and julia-like control
structures.
Though it may look like a markup language, efus
is not markup but instead instructions to construct
components.

## Reactivity

Efus uses a few types, like [IonicEfus.Catalyst](@ref),
[IonicEfus.Reactant](@ref) and [IonicEfus.Reactor](@ref)
to track and react to value changes.

### The `ionic` expressions

These are simply peices of julia code, where
[IonicEfus.Ionic.translate](@ref) converts
expressions preceded by a "'" to getvalue()
and assignments to setvalue! calls, so as to
help you use reactants more easily, almost
every julia expression in efus code passes
through that translation, so `ionic` is supported
almost everywhere, in for, if, expressions, ...

You also have macros at your disposal to insert
them within your code.
