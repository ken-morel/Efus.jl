# IonicEfus.jl

[![CI](https://github.com/ken-morel/IonicEfus.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/ken-morel/IonicEfus.jl/actions/workflows/CI.yml)

> [!NOTE]
> This is not very stable, but it works.

IonicEfus.jl is a julia module providing template building language and
rectivity constructs to help you build structures organised as
components. It aims for providing the base so that custom libraries
can define components to be used by a final client, but
with a set of standards to help debugging, and using
components:

- _efus_ templating lanugage, not a markup language,
  but a set of instructions for building a component.
- Support for streamed parsing via IO and channels(Good luck for
  error reporting though).
- macros providing support for code generation at macro-expansion.
- Reactivity implemented through Reactants, Reactors and Catalysts.
- Ionic, just a little tool to use reactants withough getvalue and
  setvalue!.
- Very experimental error reporting, please if you face issues,
  githubize them so I can get to fix them, sorry 🤧.
- Typing support, to help prevent errors and make your code faster.
- a little bit more...

## Efus the language

Efus, is actually a construct I had since, and tried to implement
in python, then zig, and now julia(finally found it! The match!).
It uses an identation based, pug-like syntax except for control
flow and other special constructs which are more julia-like end-ended.
It is built so as to completely integrate with your julia code, and
actually translates to julia code.

```julia
using IonicEfus
using MyComponentLib: LabelFrame

const WHAT = "Items"
const ITEMS = [...]

const itemTile = (;item) -> efus"..."

const component = efus"""
LabelFrame padding=(1, 1)
  label(frm::LabelFrame)
    Label text="List of $WHAT"
  end
  for (idx, item) in items
    if isnothing(item.idx)
      # We could also have used something()
      (item.idx = item.idx;)
    end
    itemTile item=item
  end
"""
```

I feel depressed looking all I've spent time working on just shows in
20 lines of code.

## Reactivity

A full pack of nice names, Reactant, Reactor, Catalyst, and few more
to revive your form 2 chem. Not that I love the subject, it actually
caused my worst grade

```chem
(salt + funnel + H2O ---pooring--> 😢).
```

In short:

- A `Reaction`: Links a `Catalyst`, a `Reactant` and a callback. An
  can be `inhibit!` -ed. Your usually don't have to manage this.
- A `Catalyst`: `catalyze!` and manage reactions with `Reactants` ,
  can be `denature!` -ed.
- a `Reactant` hold a value and notify all ongoing reactions when
  it's value change.
- A `Reactor`: holds several catalysts, and acts like a computed
  reactant whose value depends on other `AbstractReactive` objects
  and whose value is lazily-computed.
- `@ionic`: is just a tool, a translater, or something like that,
  I'm not so good at names, but in fact, it transforms assignments
  and getting values to ''' prepended values into
  a `IonicEfus.setvalue` and `IonicEfus.getvalue!` call.

## Getting to it

Well, this was just to briefly describe(🤧) what is there, but
to learn more about it, you could read the [IonicEfus.jl documentation](https://ionicefus.engon.rbs.cm).
I will host it there as soon as i get the docs hosted by julia
General registry docs hosting whatsoever that other modules seem to use.

If you are looking for examples of usage of this I am also
having [Gtak.jl](https://github.com/ken-morel/Gtak.jl), which
provide `IonicEfus.jl` and [Atak.jl](https://github.com/ken-morel/Atak.jl)
bindings for `Gtk4.jl`.

Well, thanks for reaching up to here, if you want to contribute,
I recently discovered `git-flow`, and finally started to memorize
those `gh pr` and `gh issue` commands.
