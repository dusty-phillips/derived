# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Build and Development
- `gleam run` - Run the main project (executes the `main()` function)
- `gleam test` - Run all tests using the gleeunit testing framework

### Testing
- `gleam test` - Runs all tests in the `test/` directory
- Tests use the gleeunit framework and follow the `*_test.gleam` naming pattern

## Project Architecture

This is a Gleam library for parsing custom types from Gleam source code that are marked with special `!codegen_type()` annotations in their docstrings.

### Core Functionality
- **Parser Module**: `src/codegen_type.gleam` contains the main parsing logic
- **Token Processing**: Uses `glexer` for lexical analysis and `glance` for AST parsing
- **Pattern Matching**: Searches for `!codegen_type()` declarations in type docstrings using regex

### Key Types
- `CodegenType`: Represents a parsed Gleam custom type with metadata (span, docstring, attributes, variants)
- `Variant`: Represents type constructors with fields and attributes
- `Field`: Either labelled or unlabelled fields in type constructors
- `FieldType`: Type representations including named types, tuples, functions, and variables

### Dependencies
- `glexer` (>= 2.2.1): Lexical analysis of Gleam source code
- `glance` (>= 5.0.0): AST parsing for Gleam
- `gleam_regexp`: Pattern matching for extracting codegen annotations
- `gleeunit`: Testing framework

### Parser Implementation Details
- The parser is implemented as a state machine using `parse_loop` that processes tokens sequentially
- Only docstrings followed by `type` declarations are considered
- The regex pattern `!codegen_type\(([a-z][a-z_/]*)\)\s*$` extracts module names from docstrings
- Parser is incomplete: variant parsing (`parse_variant`) and parameterized types are not yet implemented (marked with `todo`)

### Current Limitations
- Only handles empty custom types (no variants) - variant parsing is incomplete
- Type parameters are not yet supported
- Attributes parsing is stubbed out
- The parser ignores all non-type syntax (functions, constants, imports)