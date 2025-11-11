# Reactivity guide

Efus implements a few helpers to help you manage
reactivity.

## Reactive objects

- [`Ionic.AbstractReactive`](@ref)

Reactive objects are instances of subtypes
of [`Ionic.AbstractReactive`](@ref){T}.
Where T is the contained type.

They implement:

- [`Ionic.setvalue!`](@ref)
- [`Ionic.getvalue`](@ref)

You are provided with two reactive types:

- [`Ionic.Reactant`](@ref)
- [`Ionic.Reactor`](@ref)
You can learn more on [Reactors](./reactors.md)
and [Ionic syntax](./ionic.md).

## Catalysts

- [`Ionic.Catalyst`]

Catalyses help you manage subscriptions to reactants.
They implement:

- [`Ionic.catalyze!`](@ref)
- [`Ionic.denature!`](@ref)


