# Snippets

- [`IonicEfus.Snippet`]
- [`IonicEfus.@Snippet`]
- [`IonicEfus.Ast.Snippet`]


Snippets are functions which create ui
components. Snippet are simply
typed wrappers around the function.
They are used to create ui component
builders from within efus code,
used as slots. They have two behaviours:

- **When declared in a componentcall**:
  They are passed as argument to the function

  ```julia
  function ItemList(;items, builder::@Snippet{item::Number})
    return [builder(x) for x in items]
  end
  efus"""
  ItemList items=(1, 2, 3)
    builder(item::Number)
      ...
    end
  """
  ```
- **When declared in a block**:
  The snippets are grouped to the top and
  are available in the block's scope.

  ```julia
  efus"""
  Item(...)
    ...
  end
  Foo # You can use it as component builder
    Item ...
    Foo builder=Item
  """
  ```
  ```

If you call a snippet with positional arguments, they
will be converted to keyword arguments before calling.

You are provided `@Snippet` to help you define snippets.

```julia
Snippet{NamedTuple{(:foo,), Tuple{Bar}}}

@Snippet{foo::Bar}
```
