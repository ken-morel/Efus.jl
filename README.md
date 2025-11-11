# Efus.jl

[![CI](https://github.com/ken-morel/Efus.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/ken-morel/Efus.jl/actions/workflows/CI.yml)

> [!NOTE]
> This is not very stable, but it works.

Efus.jl is a julia module providing template building language and
rectivity constructs from [Ionic.jl](https://github.com/ken-morel/Ionic.jl)
to help you build structures organised as components. It aims for providing
 the base so that custom libraries
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
using Efus
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

> [!TIP]
> With [JETLS.jl](https://github.com/aviatesk/JETLS.jl/) you can
> have parse error inline messages _as you code_,
> along with unused variables, and other lsp functionalities.

## Reactivity with Ionic.jl

see [Ionic.jl](https://github.com/ken-morel/Ionic.jl)

## Getting to it

Well, this was just to briefly describe(🤧) what is there, but
to learn more about it, you could read the [Efus.jl documentation](https://efus.engon.rbs.cm).
I will host it there as soon as i get the docs hosted by julia
General registry docs hosting whatsoever that other modules seem to use.

If you are looking for examples of usage of this I am also
having [Gtak.jl](https://github.com/ken-morel/Gtak.jl), which
provide `Efus.jl` and [Atak.jl](https://github.com/ken-morel/Atak.jl)
bindings for [Gtk4.jl](https://github.com/JuliaGtk/Gtk4.jl).

Well, thanks for reaching up to here, if you want to contribute,
I recently discovered `git-flow`, and finally started to memorize
those `gh pr` and `gh issue` commands.
