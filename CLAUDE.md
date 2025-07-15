# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Build and Development
- `gleam run` - Run the main project (executes the `main()` function)
- `gleam test` - Run all tests using the gleeunit testing framework

### Testing
- `gleam test` - Runs all tests in the `test/` directory
- Tests use the gleeunit framework and follow the `*_test.gleam` naming pattern
- Use the echo keyword (as in `echo some_value`) for debugging

## Project Architecture

This is a Gleam library for parsing and generating code from Gleam custom types marked with special `!derived()` directives in their docstrings. It provides both parsing capabilities and code generation functionality.

### Core Functionality
- **Main Module**: `src/derived.gleam` contains the public API (`parse` and `generate` functions)
- **AST Module**: `src/derived/ast.gleam` contains the parser implementation and type definitions
- **Token Processing**: Uses `glexer` for lexical analysis of Gleam source code
- **Pattern Matching**: Searches for `!derived()` declarations in type docstrings using regex
- **Code Generation**: Inserts generated code back into source with proper BEGIN/END markers

### Key Types
- `DerivedType`: Represents a parsed Gleam custom type with metadata (span, docstring, attributes, publicity, opaque flag, type definition, derived module)
- `Type`: Represents the type definition with name, parameters, and variants
- `Variant`: Represents type constructors with fields and attributes
- `Field`: Either labelled or unlabelled fields in type constructors (`LabelledField` or `UnlabelledField`)
- `FieldType`: Type representations including named types, tuples, functions, and variables
- `Attribute`: Represents attributes like `@deprecated`, `@internal`, and `@target`
- `Publicity`: Either `Public` or `Private`

### Dependencies
- `glexer` (>= 2.2.1): Lexical analysis of Gleam source code
- `gleam_regexp`: Pattern matching for extracting derived annotations
- `gleeunit`: Testing framework

### Parser Implementation Details
- The parser is implemented as a state machine using `parse_loop` that processes tokens sequentially
- Only docstrings followed by `type` declarations are considered
- The regex pattern `!derived\(([a-z][a-z_/]*)\)\s*$` extracts module names from docstrings
- Parser is fully implemented with support for:
  - Complex variant parsing with fields (labelled and unlabelled)
  - Type parameters for generic types
  - Attributes parsing (`@deprecated`, `@internal`, `@target`)
  - Publicity modifiers (`pub`, `pub opaque`)
  - Nested type structures (tuples, functions, parameterized types)
  - Module-qualified types (e.g., `option.Option(String)`)

### Current Capabilities
- **Parsing**: Handles all custom type variations including empty types, variants with fields, and parameterized types
- **Complex Types**: Supports complex field types including tuples, functions, and nested parameterized types
- **Attributes**: Parses type and variant attributes (`@deprecated`, `@internal`, `@target`)
- **Modifiers**: Handles public and opaque type modifiers (`pub`, `pub opaque`)
- **Multiple Derivations**: Supports multiple `!derived()` directives per type
- **Code Generation**: Inserts generated code after type definitions with proper markers
- **Marker Replacement**: Automatically replaces existing generated code on re-runs
- **Error Handling**: Comprehensive error handling with meaningful error messages
- **Robust Parsing**: Ignores all non-type syntax (functions, constants, imports)

### API Functions
- `derived.parse(source: String) -> List(DerivedType)`: Parse source and return derived types
- `derived.generate(source: String, callback: fn(DerivedType) -> Result(String, Nil)) -> String`: Generate code and insert into source

### Examples
- **JSON Schema Generator**: `examples/json_schema/` - Complete example showing JSON schema generation from Gleam types