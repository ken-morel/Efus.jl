# Efus.jl

[![wakatime](https://wakatime.com/badge/github/ken-morel/Efus.jl.svg)](https://wakatime.com/badge/github/ken-morel/Efus.jl)

Hello, Efus.jl is a component language and definitions to create component based reactive ui's.
Efus provides you a language and set of tools to add an easy way to create reactive uis for your
ui toolkit.

To work, Efus bases on a some classes or concepts I would quickly explain.

## Component Templates

A template is the base for creating a component, it contains Parameters names, types and defaults
and the component's backend's constructor [Component Backends].
Template backends are simple types which identify components and templates, as a fact
their signatures are `Component{<:TemplateBackend}` and `EfusTemplate{<:TemplateBackend}`.

`EfusTemplate` is the basic component template, here is an example.

```julia
struct LabelBackend <: TemplateBackend end

const label = Efus.EfusTemplate(
    :Label, # the component name
    LabelBackend, # the backend constructor
    Efus.TemplateParameter[
        :text! => String,          # required
        :justify => JustifyMode,   # non-required
        :width => Integer => 300,  # non-required and default value
    ]
)
```

Templates get automatically instantiated when writing efus code, but can also be instantiated manually by
calling them with three arguments:

```julia
(template::EfusTemplate)(
    parent::union{abstractcomponent, nothing},
    params::dict{symbol, any},
    namespace::abstractnamespace,
)::Component
```

## Components

Components are mostly where most of the work happens, they possess the three main methods which manages
ui at runtime:

- `mount!`: Creates the component mount(a container to the actual widget) and binds them together.
- `update!`: Reflects changes on the component to the mount
- `unmount!`: unlinks and destroys the component from it's mount.

Component arguments can be accessed by indexing(e.g `comp[:username]`)

This is an example definition for an almost complete but usable component, template and backend.

```julia
struct BoxBackend <: AttrapeBackend end

const Box = Component{BoxBackend}

struct Mount <: Efus.AbstractMount end

function Efus.mount!(c::Box)
    c.mount = Mount()
    mount!.(c.children)
    return c.mount
end

function Efus.update!(c::Box)
  if :spacing in c.dirty
    ...
  end
end

const box = EfusTemplate(
    :Box,
    BoxBackend,
    Efus.TemplateParameter[
        :spacing => Integer,
    ]
)
```

## Efus objects

Efus provides builtin helper objects accepted as arguments, includingg EEdgeInsets, EOrient, and further
which will be defined in another doc.

## Namespaces

Namespaces hold variables, templates and other data used in evaluating efus code.
They are all descendandants of `AbstractNamespace` and include `DictNamespace` and `ModuleNamespace`.

## The efus language

Getting to the actual stuff, the efus language is simply an easy way of calling components. It is pretty simple
just looks like This

```pug
using MyLib

Container padding=20x30
  Label text="Hello world" justify=c
  Button clicked=(mycallback) text="Hello world"
```

It supports basic control flow `if` and `for`, julia code snippets and a little more.
Efus is not markup, but instead step by step instructions on composing components, reason why there are no
closing tags making the hierarchy purely indentation dependent.

Efus code can be parsed at runtime by using the Parser structure, but most at times it is preferable to
parse the code at macro expansion time using `@efus_str`, or to parse and evaluate it at macro expansion time
using `@efuspreeval_str` if the backend supports it. If any error happens, the error will be returned in place
of the efus code, except using `@efusthrow_str`.

```julia
code = @efus"Digit id=4"
# OR
code = @efuspreeval"Digit id=4"

iserror(code) && Efus.display(code)
```

## Custom templates

One good thing in components, is to make them composable, CustomTemplate permit's you to define a
template actually associating it to efus code, to create a component composed of other ones.

## More, more

Well, this has a little few more to show, but I will scratch myself to make a doc for that.

Tip, for inline code for documenters, gemini adviced my `pug` and `yaml` lexers

