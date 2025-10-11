# Control flow

## If

- [`IonicEfus.Ast.If`](@ref)
- [`IonicEfus.Gen.generate(::IonicEfus.Ast.If)`](@ref)

efus if syntax is almost and why not actually
identical to julia's.

```julia
if foo * c / 4(
    3x + 2
  ) > 5
  Label foo=bar
elseif (juliaexpr)
  <block>
else
  <block>
end
```

If conditions are simply parsed, transcribed with ionic(if it
contains any `'` quoted value), and then substituted
in an actual if statement.
Since efus does not parse any of the content in the expression
you have full control there, but note that efus parser does not
consider begin - end, so always wrap them in  braces(`()` or `{}` or `[]`).

## For

- [`IonicEfus.Ast.For`](@ref)
- [`IonicEfus.Gen.generate(::IonicEfus.Ast.For)`](@ref)

The for loop again is similar to julia's syntax,
you can use usual things like destructuring, ...
For loops also support an else block which runs
if `isempty` returns true on the computed iterator value.

```julia
for (idx, val) in enumerate(...)
  <code block>
else
  <code block>
end
```
