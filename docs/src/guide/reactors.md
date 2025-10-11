# Reactors

- [`IonicEfus.Reactor`](@ref)

Reactors are reactive values
whose values depend on computing other
reactants, they may have dependencies
then it will notify subscribed values
when any of them change, but
will only compute it's value
when getvalue is called, except
it is created with `eager=true`.

You are provided with two macros
to create reactors:

- [`IonicEfus.@reactor`](@ref)
- [`IonicEfus.@radical`](@ref)

`@radical` permits you to create
a statement which re-runs when the value
of one of it's dependencies change,
it does so by reacting a Reactor
with eager=true, and returns the underlying
reactor.

```julia
r = Reactor{String}(
  () -> @ionic a' * b',
  (v) -> (b' = ""; a' = v),
  [a, b],
)
v = @reactor (a' * b') ((v) -> (b' = ""; a' = v)

c = Reactant(@ionic a' * b')

@radical c' = a' * b'
```
