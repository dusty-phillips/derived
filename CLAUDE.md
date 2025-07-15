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

This is a Gleam library for parsing custom types from Gleam source code that are marked with special `!derived()` annotations in their docstrings.

### Core Functionality
- **Parser Module**: `src/derived.gleam` contains the main parsing logic
- **Token Processing**: Uses `glexer` for lexical analysis of Gleam source code
- **Pattern Matching**: Searches for `!derived()` declarations in type docstrings using regex

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
- Handles all custom type variations including empty types, variants with fields, and parameterized types
- Supports complex field types including tuples, functions, and nested parameterized types
- Parses type and variant attributes
- Handles public and opaque type modifiers
- Supports multiple derived annotations (uses the last one found)
- Comprehensive error handling with meaningful error messages
- The parser ignores all non-type syntax (functions, constants, imports)