# derived

[![Package Version](https://img.shields.io/hexpm/v/derived)](https://hex.pm/packages/derived)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/derived/)

A Gleam library for parsing and generating code from Gleam custom types marked
with special `!derived()` directives in their docstrings. Use it to build code
generators for serialization, validation, documentation, and more.

## Features

- **Docstrings**: Parses documentation as part of the AST
- **Parse Gleam types**: Extract detailed type information from source code
- **Code generation**: Insert generated code back into source with proper markers
- **Rich type support**: Handles variants, fields, generics, attributes, and more
- **Marker replacement**: Automatically replaces existing generated code on re-runs
- **Multiple derivations**: Support multiple `!derived()` directives per type

## Quick Start

```sh
gleam add derived@1
```

### Basic Parsing

```gleam
import derived

pub fn main() -> Nil {
  let gleam_source = "
    /// A custom type for demonstration
    /// !derived(json)
    pub type Person {
      Person(name: String, age: Int)
    }
  "

  let derived_types = derived.parse(gleam_source)
  // Returns a list of DerivedType records containing parsed type information
}
```

### Code Generation

```gleam
import derived
import derived/ast
import gleam/list
import gleam/string

pub fn main() -> Nil {
  let source = "
    /// User type
    /// !derived(json_schema)
    pub type User {
      /// A regular user account
      User(name: String, age: Int)
      /// An admin user account
      Admin(name: String, permissions: List(String))
    }
  "

  let result = derived.generate(source, generate_json_schema)
  // Returns source with generated JSON schema inserted
}

fn generate_json_schema(derived_type: ast.DerivedType) -> Result(String, Nil) {
  case list.contains(derived_type.derived_names, "json_schema") {
    True -> {
      let schema = build_json_schema(derived_type.parsed_type)
      Ok(
        "const "
        <> string.lowercase(derived_type.parsed_type.name)
        <> "_schema = "
        <> schema
        <> ";",
      )
    }
    False -> Error(Nil)
  }
}
```

## How it works

1. **Mark types**: Add `!derived(generator_name)` to type docstrings
2. **Parse or generate**: Use `derived.parse()` for inspection or
   `derived.generate()` for code generation
3. **Process results**: Work with parsed type information or insert generated
   code

## Examples

I had claude throw together a quick
[JSON Schema Generator](https://github.com/dusty-phillips/gleam-derived/tree/main/examples/json_schema)

## Documentation

API documentation can be found at <https://hexdocs.pm/derived>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## FAQ

- **Why not use [glance](https://hexdocs.pm/glance/glance.html)**?

You should!

I wrote this because glance doesn't currently support docstrings in types.
[Issue here](https://github.com/lpil/glance/issues/2) When that issue is
closed, I'll switch this project to use Glance and remove the AST module.

- **Why not use [deriv](https://github.com/bchase/deriv/blob/master/README.md)?**

You should!

For one thing, it's two fewer characters to type! Think of the LLM tokens
you'll save!

To be honest, I didn't know `deriv` existed when I started this. I think this
package handles documentation strings better than `deriv` (because it doesn't
depend on glance), but it probably has some AST parsing bugs (also because it
doesn't depend on glance).

This package also supports comment markers in code so you can regenerate output
when you change the type.

- **Shouldn't this be in the gleam compiler?**

Maybe? In gleam, `derive` is a reserved keyword so the dev team is obviously
thinking about it. This project is a chance to explore ho that might might look
and what use cases it can solve.

- **What should I use this for?**

- Generating serializers and deserializers to various formats.
- Generating a [glint](https://hexdocs.pm/glint/index.html) CLI parser based
  solely on an input type.
- Generating schemas for various protocols.
- Generating stubs for wisp handlers or lustre clients
