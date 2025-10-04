# Project Overview

This project, `IonicEfus.jl`, is a Julia module for building component-based user interfaces. It introduces a declarative, pug-like language called "efus" for defining UI structures. The core of the project is a parser for the efus language, a code generator that translates efus code into Julia expressions, and a reactivity system for creating dynamic UIs.

The main technologies used are:
- **Julia**: The primary programming language.
- **efus**: A custom, indentation-based language for defining UI components.
- **Ionic**: A reactive programming model with reactants, catalysts, and reactors.

The project is structured into several modules:
- **Tokens**: Handles the tokenization of efus code.
- **Ast**: Defines the Abstract Syntax Tree for the efus language.
- **Parser**: Parses a stream of tokens into an AST.
- **Gen**: Generates Julia code from the AST.
- **Reactants**: Implements the reactivity system.
- **Component**: Defines the base `AbstractComponent` type and component lifecycle functions.

# Building and Running

There are no explicit build commands in the `Project.toml` file. To use this module, you would typically install it as a dependency in another Julia project.

To run the tests, you can use the Julia package manager:

```julia
using Pkg
Pkg.test("IonicEfus")
```

# Development Conventions

## Coding Style

The code follows standard Julia conventions. It is organized into modules, and uses features like multiple dispatch and metaprogramming.

## Testing

The project has a `test` directory with a `runtests.jl` file, which is the entry point for the test suite. The tests use the `Test` module from the Julia standard library.

## Contribution

There are no explicit contribution guidelines in the repository. However, the presence of a `.github` directory with CI workflows suggests that contributions are welcome and are expected to pass the automated tests.
