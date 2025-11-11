# Efus.jl

[![CI](https://github.com/ken-morel/Efus.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/ken-morel/Efus.jl/actions/workflows/CI.yml)
[![code style: runic](https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black)](https://github.com/fredrikekre/Runic.jl)


`Efus.jl` is a reactive component framework for Julia. It provides a declarative, indentation-based templating
language that compiles directly to Julia code. Combined with reactivity system from `Ionic.jl` to build complex,
dynamic user interfaces and other component-based systems in a clean and maintainable way.

The core philosophy of Efus is to blend the readability of a templating language
with the power and performance of native Julia code.

## Core Features

-   **Declarative Syntax**: Write component hierarchies in a clean, minimal, indentation-based syntax.
-   **Ahead-of-Time Compilation**: Efus templates are parsed and converted into pure Julia expressions at macro-expansion time, resulting in zero runtime overhead.
-   **Powerful Reactivity**: Build UIs that automatically update when your data changes using `Reactant`s (state) and `Reactor`s (computed values).
-   **Component-Based Architecture**: Encapsulate logic and UI into reusable components with a well-defined lifecycle (`mount!`, `update!`, `unmount!`).

## The Efus Templating Language

The `@efus_str` macro is the entry point to the Efus language. It parses the template and generates corresponding Julia code.

### 1. Component Calls

Instantiate a component by its name, followed by properties. This syntax is compiled into a regular Julia constructor call.

-   **Syntax**: `ComponentName property="value" another=variable`
-   **Strings**: Use double quotes for string literals (e.g., `text="Hello"`).
-   **Variables**: Pass Julia variables directly (e.g., `width=my_width`).
-   **Boolean Props**: A property without a value is treated as `true` (e.g., `disabled` is equivalent to `disabled=true`).

```julia
# This Efus code...
efus"""
MyComponent text="Click Me" width=200 active
"""

# ...is compiled into this Julia code:
# MyComponent(text="Click Me", width=200, active=true)
```

### 2. Nesting Components

Create component hierarchies through indentation. The children are passed as a `Vector{Component}` to the parent's constructor.

```julia
# This Efus code...
efus"""
Window title="My App"
  Box orientation=:vertical
    Label text="Welcome!"
"""

# ...is compiled into this Julia code:
# Window(title="My App", children=[
#   Box(orientation=:vertical, children=[
#     Label(text="Welcome!")
#   ])
# ])
```

### 3. Control Flow

Use standard Julia `if`/`elseif`/`else` and `for` loops to conditionally or dynamically generate components,
you may add an `else` clause to for loops which evalueates when the iterable
responds positively to `isempty`.

**If/Else Statements:**

```julia
efus"""
if is_loading'
  Spinner
else
  Label text="Content Loaded"
end
"""
```

**For Loops:**

```julia
items = ["One", "Two", "Three"]

efus"""
for item in items
  ListItem text=item
else
  Nothing
end
"""
```

### 4. Snippets (Reusable Blocks)

Snippets are reusable blocks of Efus code, similar to functions or slots. They allow you to pass templating code as an argument to another component,
when defined in a component call, but in code blocks or at top level it creates
an anonymous function available in local scope.
enabling powerful composition patterns like layouts.

-   **Definition**: `snippetName(arg1, arg2::Type=default) ... end`
-   **Passing**: Pass them to components like any other property.

```julia
efus"""
# Define a snippet for the header
header_content(;title)
 Label font_weight=:bold text=title
end

# Pass the snippet to a Card component that knows how to render it
Card
  content(title) #pass content() as argument
    Label text="This is the card content."
    header_content title="title is $title"
  end
"""
```

### 5. Embedding Julia Code

You can embed arbitrary Julia code within parentheses `()` and define anonymous
functions which contains efus expressions with `() -> <efus expr>`. This is useful for
 defining local variables, running logic, or calling functions directly within your template.

```julia
efus"""
(
  items = ["One", "Two", "Three"];
  current_user = "Admin"
)

Label text="Welcome, $(current_user)!"
for item in items
  Label text=item
"""
```

## The Component System

### `abstract type Component end`

This is the supertype for all components. To create a new component, you define a `struct` that subtypes `Component` and implement its lifecycle methods.

### Component Lifecycle

-   `mount!(component, parent)`: Called to initialize the component. This is where you create backend objects (e.g., widgets, renderers), set up reactive subscriptions, and attach the component to its parent.
-   `update!(component)`: Called when a component's properties have been marked as "dirty" (changed). This is where you apply updates to the backend objects.
-   `unmount!(component)`: Called to clean up all resources (e.g., destroy widgets, call `denature!` on catalysts) to prevent memory leaks.

### Example: A Backend-Agnostic Counter Component

This example shows how the concepts fit together, without tying it to a specific UI backend.

```julia
using Efus, Ionic

# 1. Define the Component Struct
struct Counter <: Component
  # --- State ---
  count::Reactant{Int}

  # --- Internal Fields ---
  on_click::Function
  catalyst::Catalyst
  backend_ref # A reference to the backend object
end

# 2. Define the Constructor
function Counter(; initial_value=0, on_click=()->nothing)
    Counter(Reactant(initial_value), on_click, Catalyst(), nothing)
end

# 3. Implement Lifecycle Methods
function Efus.mount!(c::Counter, parent)
  # Create the backend representation (e.g., a button)
  c.backend_ref = create_backend_button("Count: $(c.count[])")

  # Set up the click handler
  set_backend_onclick(c.backend_ref, () -> c.on_click(c))

  # Set up reactivity: when `count` changes, update the button text
  catalyze!(c.catalyst, c.count) do count
    set_backend_button_text(c.backend_ref, "Count: $(count[])")
  end

  # Attach to the parent in the backend
  add_to_backend_parent(parent, c.backend_ref)
end

function Efus.unmount!(c::Counter)
  # Clean up subscriptions to prevent memory leaks
  denature!(c.catalyst)
  # Destroy the backend object
  destroy_backend_object(c.backend_ref)
end

# --- Usage ---
increment(c::Counter) = c.count[] += 1

counter = nothing
content = efus"""
Counter initial_value=5 onclick=() -> (increment(content[1]))
"""
```

## Reactivity with `Ionic.jl`

Efus's reactivity is powered by `Ionic.jl`. The `'` syntax is automatically enabled inside `@efus_str` templates, making it easy to work with reactive state.

```julia
efus"""
(
    first_name = Reactant("John");
    last_name = Reactant("Doe");
    full_name = @reactor "$(first_name') $(last_name')";
)

Label text="Full Name: $(full_name')"
Entry placeholder="First Name" onchange=(new_text -> first_name' = new_text)
"""
```

For a full overview of the reactivity system, see the [`Ionic.jl` README](https://github.com/ken-morel/Ionic.jl).

## Style Guide

For conventions on indentation, naming, and formatting, please see the [STYLE_GUIDE.md](./STYLE_GUIDE.md).

## How Efus Works: The Compilation Pipeline

A key feature of Efus is its performance. This is achieved because `efus"..."` is not an interpreted language; it's a macro that compiles your template into native Julia code before your program even runs. This means you get the readability of a templating language with zero runtime overhead.

The process is, in short:
1.  **Tokenizing**: The raw text is broken down into fundamental tokens (like identifiers, keywords, and indentation).
2.  **Parsing**: The tokens are used to build an Abstract Syntax Tree (AST), which is a hierarchical representation of your component structure.
3.  **Code Generation**: The AST is traversed and converted into a standard Julia `Expr` (expression). During this stage, reactive `'` syntax is also translated into `getvalue` and `setvalue!` calls.

The final Julia expression is what gets compiled, making your Efus templates just as fast as handwritten Julia code.

## Further Reading

-   [Creating Components](./CREATING_COMPONENTS.md): A detailed guide for building your own Efus components and component libraries.

For conventions on indentation, naming, and formatting, please see the [STYLE_GUIDE.md](./STYLE_GUIDE.md).
