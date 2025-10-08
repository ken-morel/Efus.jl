# Gemini Code Assistant Context

This document provides context for the Gemini code assistant to understand the `IonicEfus.jl` project.

## Project Overview

`IonicEfus.jl` is a Julia module that provides a templating language called "Efus" for building reactive components. The project is a compiler for the Efus language, and includes the following components:

*   **Tokenizer:** Converts Efus code into a stream of tokens.
*   **Parser:** Parses the token stream and builds an Abstract Syntax Tree (AST).
*   **Code Generator:** Traverses the AST and generates Julia code.

The main entry point for users is the `@efus_str` macro, which allows them to write Efus code directly in their Julia source files. The project also provides macros for reactive programming (`@ionic`, `@reactor`, `@radical`).

## Building and Running

The project is a standard Julia package.

### Dependencies

The project dependencies are listed in `Project.toml`:

*   `FunctionWrappers.jl`
*   `MacroTools.jl`
*   `Test.jl`
*   `Documenter.jl` (for documentation)

### Running Tests

To run the tests, use the following command from the project root:

```bash
julia --project -e 'using Pkg; Pkg.test()'
```

### Building Documentation

To build the documentation, navigate to the `docs/` directory and run:

```bash
julia --project -e 'using Pkg; Pkg.instantiate(); include("make.jl")'
```

## Development Conventions

*   **Code Style:** The code is formatted according to the standard Julia style guidelines.
*   **Testing:** The project uses the `Test.jl` framework for unit testing. Tests are located in the `test/` directory.
*   **Documentation:** The project uses `Documenter.jl` to generate documentation from the docstrings in the source code. The documentation source files are in the `docs/` directory.
*   **Modularity:** The code is organized into several modules, each with a specific responsibility (e.g., `Tokens`, `Lexer`, `Parser`, `Ast`, `Gen`).
