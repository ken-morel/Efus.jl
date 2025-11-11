"""
    struct Julia <: Expression

Julia represents any efus expression, which
actually parses and generate directly from
julia itself. I includes strings, numeric 
literals, if expressions, and almost 
every julia-like expression expect
reactor definitions. The content always
passes through transcribing when generating
code.

# Syntax

The basic julia expression constitutes of a
braced expression:

```julia
(foo; bar' = 44)
```
But many other literals evaluate to expressions:

- "foo \\\$bar"
- 45_4.5e5px
- :a_symbol!even_here

!!! NOTE
    Number multiples like 45im only support letters
    as variables names, and not the usual julia
    !, pi, .. stuff.
"""
Base.@kwdef struct Julia <: Expression
    expr::Any
    token::Union{Tokens.Token,Nothing} = nothing
end
public Julia

"""
    struct Reactor <: Expression

A reactor is a container where several reactions
between reactans can take place, it has a final
value, which can be gotten with [`Ionic.getvalue`](@ref) and
[`Ionic.setvalue!`](@ref) and which is lazily computed. And
holds a getter and setter expressions.
They support and use reactive syntax, but in addition
every marked reactant in the reactive getter will be
considered a dependency of the reactor, causing it
to notify all the elements subscribed to the reactor that
it's value changed when any of it's dependencies changed,
but only recomputing it's value when queried and any of
it's reactants changed since it's last update.
It has a type assertion at the end which specifies the
type of the reactor, if this is not included, it is
instead interpreed as a normal [`Ast.Julia`](@ref) expression.

# Example
#
```julia
(foo' * reactants[bar']')::String
```
"""
Base.@kwdef struct Reactor <: Expression
    expr::Any
    type::Any
    tokens::Union{@NamedTuple{expr::Tokens.Token,type::Tokens.Token},Nothing} = nothing
end
public Reactor

"""
    struct Vect <: Expression

It is a list of efus expressions, with vector syntax.
It effectively generates a julia vector.
"""
Base.@kwdef struct Vect <: Expression
    items::Vector{Expression}
    tokens::Union{@NamedTuple{start::Tokens.Token,stop::Tokens.Token},Nothing} = nothing
end
public Vect

"""
    struct Arrow <: Expression

Represents an efus arrow function,
it has the syntat:

`(Julia|Reactor) -> (Expression)`

It renders to an actual julia function.
You can have kwargs of course.
If you use a Reactor, the reactor type
expr is used as return type for the function.
"""
Base.@kwdef struct Arrow <: Expression
    params::Union{Reactor,Julia}
    body::Expression
    token::Union{Tokens.Token,Nothing} = nothing
end
public ArrowFn
