# Reactivity guide

Efus implements a few helpers to help you manage
reactivity.

## Reactive objects

- [`IonicEfus.AbstractReactive`](@ref)

Reactive objects are instances of subtypes
of [`IonicEfus.AbstractReactive`](@ref){T}.
Where T is the contained type.

They implement:

- [`IonicEfus.setvalue!`](@ref)
- [`IonicEfus.getvalue`](@ref)

You are provided with two reactive types:

- [`IonicEfus.Reactant`](@ref)
- [`IonicEfus.Reactor`](@ref)
You can learn more on [Reactors](./reactors.md)
and [Ionic syntax](./ionic.md).

## Catalysts

- [`IonicEfus.Catalyst`]

Catalyses help you manage subscriptions to reactants.
They implement:

- [`IonicEfus.catalyze!`](@ref)
- [`IonicEfus.denature!`](@ref)


