# The Efus Compilation Pipeline

The `@efus_str` macro is the core of the Efus templating engine. It transforms the human-readable Efus syntax into highly efficient, native Julia code. This transformation happens at compile time (specifically, during macro expansion), meaning there is no runtime interpretation or performance overhead from using Efus templates.

This document details the stages of that compilation process.

## Stage 1: Tokenizer (Lexer)

**Input**: A raw string of Efus code.
**Output**: A stream of `Token`s.

The first step is to break the input string into a sequence of fundamental units, or "tokens". The tokenizer scans the string and identifies identifiers, keywords, operators, string literals, and indentation changes.

For example, the line `Label text="Hello"` is converted into a sequence like this:

-   `IDENTIFIER("Label")`
-   `WHITESPACE`
-   `IDENTIFIER("text")`
-   `EQUAL`
-   `STRING("Hello")`
-   `NEWLINE`

Indentation is also a critical token. The tokenizer tracks the current indentation level and emits `INDENT` and `DEDENT` tokens when the level changes, which is essential for parsing the nested structure of the template.

## Stage 2: Parser

**Input**: A stream of `Token`s.
**Output**: An Abstract Syntax Tree (AST).

The parser takes the flat stream of tokens and constructs a hierarchical representation of the code's structure, known as an Abstract Syntax Tree (AST). The AST is a tree of Julia `struct`s that represents the relationships between different parts of the code, such as component calls, nested children, and control flow blocks.

For example, this Efus code:

```efus
Box
  Label text="Hi"
```

Would be parsed into an AST that looks something like this in principle:

```
ComponentCall(
  name: "Box",
  properties: [],
  children: [
    ComponentCall(
      name: "Label",
      properties: [
        Property(name: "text", value: "Hi")
      ],
      children: []
    )
  ]
)
```

This tree structure perfectly captures the parent-child relationships defined by the indentation in the source template.

## Stage 3: Code Generator

**Input**: The Abstract Syntax Tree (AST).
**Output**: A Julia `Expr` (expression).

The final stage is to traverse the AST and generate the corresponding Julia code. The code generator walks through each node of the AST and builds up a Julia `Expr` object.

-   A `ComponentCall` node in the AST is converted into a Julia constructor call, e.g., `:(Box(...))`.
-   Nested children are converted into a `Vector` that is passed to the parent's constructor, typically as a `children` keyword argument.
-   Control flow nodes (`if`, `for`) are converted into their equivalent Julia `if` blocks and `for` loops.
-   `'` syntax is transcribed into `getvalue` and `setvalue!` calls via `Ionic.transcribe`.

The resulting `Expr` is what the `@efus_str` macro returns. Julia then compiles this expression into highly optimized machine code, just as it would with any other handwritten Julia code. This is the key to Efus's performance.
