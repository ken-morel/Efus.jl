# Creating Efus Components

This guide provides an in-depth look at how to create your own components in Efus, drawing best practices from the `Gtak.jl` framework. A component is the fundamental building block of an Efus application, encapsulating state, logic, and a piece of the user interface (or any other backend representation).

## 1. The Component Struct and Macros

At its core, a component is a Julia `struct` that subtypes `Efus.Component`. This struct holds the component's state, properties, and any internal data it needs to manage its lifecycle.

In `Gtak.jl`, specialized macros (`@gtakcomponent` and `@gtakwidgetcomponent`) are used to streamline component definition and automatically inject common fields.

### `@gtakcomponent` (Base Component Macro)

This macro, defined in `Gtak.jl/src/component.jl`, is used for general-purpose components. It automatically adds the following essential internal fields to your component struct:

-   `_dirty::Set{Symbol}`: Tracks which properties have changed, used by the `update!` mechanism.
-   `_lock::ReentrantLock`: Provides thread-safe access to the component's internal state.
-   `_catalyst::Catalyst`: Manages all reactive subscriptions made by the component, crucial for cleanup.
-   `_parent::Union{Component, Nothing}`: A reference to the component's parent in the component tree.
-   `_widget::Union{Gtk4.GLib.GObject, Nothing}`: A reference to the primary backend object (e.g., a GTK widget) managed by this component.

**Example Usage:**

```julia
using Efus, Ionic, Gtk4 # Assuming Gtk4 for backend_ref type

@gtakcomponent struct MyCustomComponent <: Efus.Component
  # --- Component-specific properties ---
  my_property::MayBeReactive{String} = "default"
  another_property::Int = 0

  # --- Children (if it's a container) ---
  children::Vector{Efus.Component} = []
end
```

### `@gtakwidgetcomponent` (Widget-Specific Macro)

This macro, defined in `Gtak.jl/src/widgets/widgets.jl`, is built on top of `@gtakcomponent`. It's designed for components that directly wrap a single backend widget (like a `GtkButton` or `GtkLabel`). In addition to the fields from `@gtakcomponent`, it automatically injects a comprehensive set of common GTK-specific properties:

-   `opacity`, `margin`, `align`, `expand`, `canfocus`, `hasfocus`, `cursor`, `sensitive`, `tooltip`, `visible`, `cssclasses`, `cssname`, `width_request`, `height_request`, `lay` (for layout parameters).

These properties are automatically made reactive (`MayBeReactive`) and are handled by shared `_gtakwidgetupdatecommon` and `_gtakwidgetmountcommon!` functions in `Gtak.jl`.

**Example Usage:**

```julia
using Efus, Ionic, Gtk4

@gtakwidgetcomponent struct MyButton <: Efus.Component
  # --- Widget-specific properties ---
  text::MayBeReactive{String} = ""
  on_click::Union{Function, Nothing} = nothing

  # --- Internal fields (if needed, beyond what macros provide) ---
  _handler_id::UInt = 0 # Example: for Gtk signal connection
end
```

## 2. The Constructor

Provide a user-friendly, keyword-based constructor for your component. The function name should match the struct name. This is the function that will be called by the compiled Efus template.

-   Initialize all properties (often with default values).
-   The internal fields (`_dirty`, `_lock`, `_catalyst`, `_parent`, `_widget`) are typically initialized by the macros and do not need explicit initialization in your constructor.

```julia
# For MyCustomComponent
function MyCustomComponent(; my_property="default", another_property=0, children=[])
  MyCustomComponent(my_property, another_property, children)
end

# For MyButton
function MyButton(; text="", on_click=()->nothing, kwargs...)
  # Pass kwargs to the macro-generated constructor for common widget properties
  MyButton(text, on_click, 0; kwargs...)
end
```

## 3. The Lifecycle Methods

The lifecycle methods are the heart of a component. You must implement them by extending the functions from the `Efus` module.

### `Efus.mount!(component, parent)`

This method is called once to bring the component to life. Its responsibilities are:

1.  **Set Parent**: Store the `parent` reference in `component._parent`.
2.  **Create Backend Objects**: Instantiate the actual backend object (e.g., a `GtkButton`, a `Plot`) using the component's initial properties. Store a reference to it in `component._widget`.
3.  **Handle Common Widget Properties (for `@gtakwidgetcomponent`)**: Call `_gtakwidgetmountcommon!(component, [])` to apply common properties like `margin`, `align`, etc., and set up their reactivity.
4.  **Set up Component-Specific Reactivity**: Use `catalyze!` with `component._catalyst` to subscribe to the component's own `Reactant` properties and state. The callbacks should update the backend object whenever the reactive data changes.
5.  **Attach to Parent**: Add the newly created backend object (`component._widget`) to the parent's backend representation.
6.  **Mount Children**: If the component is a container, iterate through `component.children` and call `mount!(child, component)` for each.

**Example (`MyButton`):**

```julia
function Efus.mount!(b::MyButton, p::Efus.Component)
  @lock b._lock begin # Use the macro-provided lock
    b._parent = p
    b._widget = GtkButton() # Create the GTK button

    # Handle common widget properties and their reactivity
    _gtakwidgetmountcommon!(b, [])

    # Set up component-specific reactivity (e.g., for `text`)
    catalyze!(b._catalyst, b.text) do new_text
      b._widget.label = new_text # Update GTK button label
    end

    # Connect GTK signal to Efus event
    b._handler_id = signal_connect(b._widget, :clicked) do _
      if !isnothing(b.on_click)
        # Schedule the callback to run on the scheduler
        schedule(b, Atak.Sched.CallbackCall(b.on_click, Atak.Sched.UserInteractive) do
          @invokelatest b.on_click()
        end)
      end
    end

    # Return the main widget
    return b._widget
  end
end
```

### `Efus.update!(component)`

This method is called when a component's properties are updated *after* it has been mounted.

-   For `@gtakwidgetcomponent`s, the `_updates` helper function (from `Gtak.jl/src/widgets/widgets.jl`) is typically used. This function iterates through the `_dirty` set, handles common widget properties via `_gtakwidgetupdatecommon`, and then calls a provided function for component-specific updates.

**Example (`MyButton`):**

```julia
function Efus.update!(c::MyButton)
  return _updates(c) do dirt # _updates handles common properties
    if dirt == :text # Handle component-specific dirty property
      c._widget.label = Efus.resolve(c.text)
    end
  end
end
```

### `Efus.unmount!(component)`

This method is called to destroy the component and clean up its resources.

1.  **Denature the Catalyst**: Call `denature!(component._catalyst)`. This is **critical** for preventing memory leaks by tearing down all reactive subscriptions.
2.  **Unmount Children**: If the component has children, recursively call `unmount!` on them.
3.  **Disconnect Signals/Events**: Disconnect any event handlers or signals (e.g., GTK signals) to prevent dangling references.
4.  **Destroy Backend Objects**: Explicitly destroy the backend widget(s) to free up memory and other system resources. For `@gtakwidgetcomponent`s, `_gtakunmountwidget!` is a helper function that handles this.

**Example (`MyButton`):**

```julia
function Efus.unmount!(b::MyButton)
  @lock b._lock begin
    # Disconnect GTK signal
    if b._widget !== nothing && b._handler_id != 0
      signal_handler_disconnect(b._widget, b._handler_id)
      b._handler_id = 0
    end

    # Handle common widget unmounting and destroy the main widget
    _gtakunmountwidget!(b; widgets = [:_widget]) # Pass widgets to destroy

    # Denature the catalyst (critical for reactivity cleanup)
    denature!(b._catalyst)

    # Clear internal state
    empty!(b._dirty)
    b._widget = nothing
    b._parent = nothing
  end
end
```

## 4. Handling Children (Container Components)

If your component is a container that can accept nested components (e.g., a `Box` or `Window`), the children will be passed as a `children::Vector{Efus.Component}` keyword argument to your constructor.

Your `mount!` method should iterate over `component.children` and call `mount!` on each child, passing its own backend widget as the parent.

```julia
@gtakcomponent struct MyBox <: Efus.Component
  children::Vector{Efus.Component} = []
end

function MyBox(; children=[])
  MyBox(children)
end

function Efus.mount!(c::MyBox, parent_widget)
  @lock c._lock begin
    c._parent = parent_widget
    c._widget = GtkBox() # Create the GTK box

    add_widget_to_container(parent_widget, c._widget) # Hypothetical

    # Mount each child, passing this Box's widget as the new parent
    for child in c.children
      mount!(child, c._widget)
    end
    return c._widget
  end
end
```