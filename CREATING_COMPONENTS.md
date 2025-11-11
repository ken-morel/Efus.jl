# Creating Efus Components

This guide provides an in-depth look at how to create your own components in Efus. A component is the fundamental building block of an Efus application, encapsulating state, logic, and a piece of the user interface (or any other backend representation).

## 1. The Component Struct

At its core, a component is a Julia `struct` that subtypes `Efus.Component`. This struct holds the component's state, properties, and any internal data it needs to manage its lifecycle.

**Best Practices for Component Structs:**

-   **Name**: Use `PascalCase` for the struct name (e.g., `DataGrid`, `SimpleButton`).
-   **State**: Use `Reactant`s from `Ionic.jl` to hold the component's internal, mutable state. This makes the component's state observable and allows other parts of the system to react to its changes.
-   **Properties**: Define fields for the properties that can be passed to the component from an Efus template. These can be `Reactant`s if the property itself needs to be reactive, or plain Julia types for static values.
-   **Catalyst**: Always include a `catalyst::Catalyst` field. This is crucial for managing the lifecycle of any subscriptions the component makes to reactive objects, preventing memory leaks.
-   **Backend Reference**: Include a field to hold a reference to the backend object the component manages (e.g., a GTK widget, an HTML element). Initialize it to `nothing`.

```julia
using Efus, Ionic

struct MyButton <: Component
  # --- Properties ---
  text::Reactant{String}
  is_disabled::Reactant{Bool}

  # --- State ---
  is_hovered::Reactant{Bool}

  # --- Internals ---
  on_click::Function
  catalyst::Catalyst
  widget # Reference to the backend widget
end
```

## 2. The Constructor

Provide a user-friendly, keyword-based constructor for your component. The function name should match the struct name. This is the function that will be called by the compiled Efus template.

-   Initialize all `Reactant` fields.
-   Initialize the `Catalyst`.
-   Set default values for optional properties.

```julia
function MyButton(; text, is_disabled=false, on_click=()->nothing)
  MyButton(
    Reactant(text),
    Reactant(is_disabled),
    Reactant(false), # internal state `is_hovered`
    on_click,
    Catalyst(),
    nothing # widget is not created yet
  )
end
```

## 3. The Lifecycle Methods

The lifecycle methods are the heart of a component. You must implement them by extending the functions from the `Efus` module.

### `Efus.mount!(component, parent)`

This method is called once to bring the component to life. Its responsibilities are:

1.  **Create Backend Objects**: Instantiate the actual backend object (e.g., a `GtkButton`, a `Plot`) using the component's initial properties. Store a reference to it in the component `struct`.
2.  **Set up Reactivity**: Use `catalyze!` to subscribe to the component's own `Reactant` properties and state. The callbacks should update the backend object whenever the reactive data changes.
3.  **Attach to Parent**: Add the newly created backend object to the parent's backend representation.

```julia
function Efus.mount!(c::MyButton, parent_widget)
  # 1. Create backend widget
  c.widget = GtkButton(c.text[])
  set_widget_disabled(c.widget, c.is_disabled[])

  # 2. Set up reactivity
  catalyze!(c.catalyst, c.text) do new_text
    set_widget_text(c.widget, new_text)
  end
  catalyze!(c.catalyst, c.is_disabled) do disabled
    set_widget_disabled(c.widget, disabled)
  end

  # (Example of reacting to internal state)
  catalyze!(c.catalyst, c.is_hovered) do hovered
    set_widget_style(c.widget, hovered ? "hovered" : "")
  end

  # 3. Attach to parent
  add_widget_to_container(parent_widget, c.widget)
end
```

### `Efus.unmount!(component)`

This method is called to destroy the component and clean up its resources.

1.  **Denature the Catalyst**: Call `denature!(c.catalyst)`. This is the **most critical step**. It tears down all subscriptions the component made, preventing memory leaks.
2.  **Destroy Backend Objects**: Explicitly destroy the backend widget to free up memory and other system resources.

```julia
function Efus.unmount!(c::MyButton)
  # 1. CRITICAL: Clean up all subscriptions
  denature!(c.catalyst)

  # 2. Destroy the backend widget
  destroy_widget(c.widget)
end
```

### `Efus.update!(component)`

This method is called when a component's properties are updated *after* it has been mounted. The default behavior is often sufficient, but you can implement custom logic if needed.

## 4. Handling Children

If your component is a container that can accept nested components (e.g., a `Box` or `Window`), the children will be passed as a `children` keyword argument to your constructor.

Your `mount!` method should iterate over `c.children` and call `mount!` on each child, passing its own backend widget as the parent.

```julia
struct Box <: Component
  children::Vector{<:Component}
  widget
end

function Box(; children)
  Box(children, nothing)
end

function Efus.mount!(c::Box, parent_widget)
  c.widget = create_backend_box()
  add_widget_to_container(parent_widget, c.widget)

  # Mount each child, passing this Box's widget as the new parent
  for child in c.children
    mount!(child, c.widget)
  end
end
```
