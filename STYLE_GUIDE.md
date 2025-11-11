# Efus Style Guide

This document outlines the recommended coding style and conventions for writing Efus templates and components. Adhering to these guidelines helps maintain readability, consistency, and maintainability across projects.

## Templating (`@efus_str`)

### Indentation

-   **Use 2 spaces for indentation.** Do not use tabs.

    ```efus
    # Correct
    MyComponent
      NestedComponent

    # Incorrect
    MyComponent
        NestedComponent
    ```

### Component Naming

-   **Use `PascalCase` for component names.** This follows the convention for Julia struct and module naming.

    ```efus
    # Correct
    Button
    AppWindow
    ListItem

    # Incorrect
    button
    app_window
    ```

### Property Naming

-   **Use `snake_case` for property names.** This aligns with Julia's general convention for function and variable names.
-   **Avoid uppercase letters and hyphens.**

    ```efus
    # Correct
    Label font_size=12 font_weight=:bold

    # Incorrect
    Label fontSize=12 font-weight=:bold
    ```

### Callback Naming

-   **Prefix callback properties with `on`.** This makes it clear that the property expects a function to handle an event.

    ```efus
    # Correct
    Button onclick=handle_click
    Slider onchange=update_value
    ```

### Property Ordering

-   **Place splatted properties (`...`) at the beginning or end of the property list.** This improves readability by keeping the explicit properties grouped together.

    ```efus
    # Correct
    Button ...common_props text="Submit"
    Button text="Submit" ...common_props

    # Less Readable
    Button text="Submit" ...common_props class="primary"
    ```

## Julia Components

### Component Structs

-   **Use `PascalCase` for the component's struct name.**
-   **Prefer `Reactant`s for internal state** to make your component reactive.
-   **Include a `Catalyst` field** to manage the component's subscriptions.

### Constructors

-   **Provide a keyword-based constructor** for a clean and readable component instantiation API.
-   **The constructor function should be named the same as the struct (`PascalCase`).**

```julia
# Correct
struct MyComponent
    text::Reactant{String}
    catalyst::Catalyst
end

MyComponent(; text) = MyComponent(Reactant(text), Catalyst())
```
