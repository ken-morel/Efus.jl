# Advanced Reactivity with Efus and Ionic.jl

Efus leverages the powerful reactivity system provided by `Ionic.jl`. While the `'` syntax (`my_reactant'` and `my_reactant' = value`) is the primary way to interact with reactive values within Efus templates and `@ionic` blocks, `Ionic.jl` also provides direct function calls and convenient shorthand syntax for working with `AbstractReactive` objects.

## Accessing and Modifying Reactive Values

Beyond the `'` syntax, you can directly interact with `Reactant` and `Reactor` values using `getvalue`, `setvalue!`, and array-like shorthand:

-   **`getvalue(my_reactive)`**: Retrieves the current value of a reactive object.
-   **`setvalue!(my_reactive, new_value)`**: Sets a new value for a reactive object and triggers notifications to its subscribers.
-   **`my_reactive[]`**: Shorthand for `getvalue(my_reactive)`.
-   **`my_reactive[] = new_value`**: Shorthand for `setvalue!(my_reactive, new_value)`.

```julia
using Ionic

my_count = Reactant(0)

# Using getvalue and setvalue!
println(getvalue(my_count)) #> 0
setvalue!(my_count, 1)
println(getvalue(my_count)) #> 1

# Using shorthand syntax
println(my_count[]) #> 1
my_count[] = 2
println(my_count[]) #> 2
```

## Reactive Patterns

### 1. Passing Reactants as Component Properties

It's common to pass `Reactant`s down to child components. This allows the child component to react directly to changes in the parent's state or even modify it (if designed to do so).

```julia
# Parent component
struct ParentComponent <: Efus.Component
  message::Reactant{String}
  catalyst::Catalyst
  # ... other fields
end

function ParentComponent(; initial_message="Initial")
  ParentComponent(Reactant(initial_message), Catalyst(), nothing)
end

function Efus.mount!(c::ParentComponent, parent_backend)
  # ... setup parent backend ...
  # Pass the reactant itself to the child
  mount!(ChildComponent(text=c.message), parent_backend)
end

# Child component
struct ChildComponent <: Efus.Component
  text::Reactant{String}
  catalyst::Catalyst
  # ... other fields
end

function ChildComponent(; text)
  ChildComponent(text, Catalyst(), nothing)
end

function Efus.mount!(c::ChildComponent, parent_backend)
  # ... create child backend (e.g., a Label) ...
  # Subscribe to the passed reactant
  catalyze!(c.catalyst, c.text) do new_text
    # Update child's backend when text changes
    update_child_backend_text(c.backend_ref, new_text)
  end
end

# Usage in Efus template:
# @efus_str """
# ParentComponent message=my_app_state.greeting
# """
```

### 2. Chaining Reactors (Computed from Computed)

`Reactor`s can depend on other `Reactor`s, forming complex computation graphs. This allows for highly modular and efficient derived state.

```julia
using Ionic

price = Reactant(10.0)
quantity = Reactant(2)

# Reactor for subtotal
subtotal = @reactor price' * quantity'

# Reactor for tax amount (depends on subtotal)
tax_rate = 0.05
tax_amount = @reactor subtotal' * tax_rate

# Reactor for total (depends on subtotal and tax_amount)
total = @reactor subtotal' + tax_amount'

println("Subtotal: ", subtotal[]) #> 20.0
println("Tax: ", tax_amount[])    #> 1.0
println("Total: ", total[])      #> 21.0

price[] = 15.0 # Update source

println("New Subtotal: ", subtotal[]) #> 30.0
println("New Tax: ", tax_amount[])    #> 1.5
println("New Total: ", total[])      #> 31.5
```

### 3. `update!` and `alter!` for Reactants

`Ionic.jl` provides helper functions for safely updating `Reactant`s, especially useful when the new value depends on the old one.

-   **`update!(fn::Function, reactive::AbstractReactive)`**: Applies a function `fn` to the current value of the reactive and sets the result as the new value. The function `fn` should take one argument (the current value) and return the new value.

    ```julia
    counter = Reactant(0)
    update!(x -> x + 1, counter) # Increments counter by 1
    println(counter[]) #> 1
    ```

-   **`alter!(fn!::Function, reactive::AbstractReactive)`**: Passes the current value of the reactive to a function `fn!` for in-place modification. After `fn!` executes, the reactive's value is set back to the (modified) object. This is useful for modifying mutable collections (e.g., `Vector`s).

    ```julia
    my_list = Reactant([1, 2, 3])
    alter!(list -> push!(list, 4), my_list) # Modifies the list in place
    println(my_list[]) #> [1, 2, 3, 4]
    ```

### 4. `sync!` for Bidirectional Binding

The `sync!` function allows you to create a bidirectional synchronization between multiple reactive values. When any of the synchronized reactives change, all others are updated to match its new value.

```julia
using Ionic

a = Reactant(1)
b = Reactant(10)
c = Reactant(100)

cat = Catalyst()
sync!(cat, a, b, c)

println("Initial: a=$(a[]), b=$(b[]), c=$(c[])") #> Initial: a=1, b=10, c=100

a[] = 5
println("After a=5: a=$(a[]), b=$(b[]), c=$(c[])") #> After a=5: a=5, b=5, c=5

c[] = 50
println("After c=50: a=$(a[]), b=$(b[]), c=$(c[])") #> After c=50: a=50, b=50, c=50

denature!(cat) # Clean up synchronization
```

## Best Practices

-   **Minimize Direct `setvalue!` Calls**: Prefer `update!` or `alter!` when the new value depends on the old, or when modifying mutable objects.
-   **Clean Up Subscriptions**: Always call `denature!(component.catalyst)` in your component's `unmount!` method to prevent memory leaks.
-   **Performance**: While `Reactor`s are lazy by default, be mindful of complex computation graphs. Profile your application if you notice performance bottlenecks.
