# Efus.jl

2 years ago, learning python, working with tkinter, I already started to look for an
easier and more beautiful way to markup user interfaces, like html but less verbose.
This is what it does, Efus is a language and set of associated tools to help you get on
adding an easier, julia-compatible way to design reactive user interfaces with you
ui toolkit. It has completely no dependency so as to ease packaging.
Efus.jl works on a few basic concepts.

## Components

A component is a manager or virtual interface to your actual widgets, a component may
wrap arround or simply expose a simple widget. A component has the role of containing
all the attributes and other properties of the widgets, so they can any time be mounted
to generate an actual widget. The are in charge of the reactivity, hieharchy and state.

There are all subclasses of the super `AbstractComponent` and Efus includes of two types:

- `Component`
- `CustomComponent`

## Template

A template object is simply defining a template to create components, they are in charge
of defining parameters, backend and also managing arguments when used in efus source.

```efus
MyComponent arg1=val1 ...
```

### CustomTemplates

Custom templates are made as templates but differ in such that they rely themselves on
other components, they are the basis of Pages and more complex interfaces.

## TemplateBackend

The full signature of `Component` is actually `Component{<:AbstractTemplateBackend}`.
The template backend is created at the same time with the component when the template is
called, and it is the only thing differentiating between components. They may store
toolkit and not widget specific data and may be any subclass of `AbstractTemplateBackend`.

## EObject

This is the parent of several efus object types generated when the code parser parses
efus source code.
