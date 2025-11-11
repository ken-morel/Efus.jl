# Efus.jl

[![CI](https://github.com/ken-morel/Efus.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/ken-morel/Efus.jl/actions/workflows/CI.yml)

`Efus.jl` is a reactive component framework for Julia. It provides a declarative, indentation-based templating language that compiles directly to high-performance Julia code. Combined with a powerful reactivity system inherited from `Ionic.jl`, Efus makes it easy to build complex, dynamic user interfaces and other component-based systems in a clean and maintainable way.

The core philosophy of Efus is to blend the readability of a templating language with the power and performance of native Julia code.

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
@efus_str """
MyComponent text="Click Me" width=200 active
"""

# ...is compiled into this Julia code:
# MyComponent(text="Click Me", width=200, active=true)
```

### 2. Nesting Components

Create component hierarchies through indentation. The children are passed as a `Vector{<:Component}` to the parent's constructor.

```julia
# This Efus code...
@efus_str """
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

Use standard Julia `if`/`elseif`/`else` and `for` loops to conditionally or dynamically generate components.

**If/Else Statements:**

```julia
@efus_str """
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

@efus_str """
for item in items
  ListItem text=item
end
"""
```

### 4. Snippets (Reusable Blocks)

Snippets are reusable blocks of Efus code, similar to functions or slots. They allow you to pass templating code as an argument to another component, enabling powerful composition patterns like layouts.

-   **Definition**: `snippetName(arg1, arg2::Type=default) ... end`
-   **Passing**: Pass them to components like any other property.

```julia
@efus_str """
# Define a snippet for the header
header_content(title) = Label font_weight=:bold text=title

# Pass the snippet to a Card component that knows how to render it
Card header=header_content("My Card")
  Label text="This is the card content."
"""
```

### 5. Embedding Julia Code

You can embed arbitrary Julia code within parentheses `()`. This is useful for defining local variables, running logic, or calling functions directly within your template.

```julia
@efus_str """
(
  items = ["One", "Two", "Three"]
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
  catalyze!(c.catalyst, c.count) do new_count
    set_backend_button_text(c.backend_ref, "Count: $(new_count)")
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

@efus_str """
Counter initial_value=5 onclick=increment
"""
```

## Reactivity with `Ionic.jl`

Efus's reactivity is powered by `Ionic.jl`. The `'` syntax is automatically enabled inside `@efus_str` templates, making it easy to work with reactive state.

```julia
@efus_str """
(
    first_name = Reactant("John")
    last_name = Reactant("Doe")
    full_name = @reactor "$(first_name') $(last_name')"
)

Label text="Full Name: $(full_name')"
Entry placeholder="First Name" onchange=(new_text -> first_name' = new_text)
"""
```

For a full overview of the reactivity system, see the [`Ionic.jl` README](https://github.com/ken-morel/Ionic.jl).

## Style Guide

For conventions on indentation, naming, and formatting, please see the [STYLE_GUIDE.md](./STYLE_GUIDE.md).
