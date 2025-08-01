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
gleam add derived
```

### Code Generation

```gleam
pub fn main() -> Nil {
  let example_types =
    "
/// A simple user type
/// !derived(json_schema)
pub type User {
  /// A regular user account
  User(name: String, age: Int, email: String)
  /// An admin user account
  Admin(name: String, permissions: List(String))
}
"

  let assert Ok(result) =
    derived.generate(example_types, "json_schema", generate_json_schema)
  io.println(result)
}

fn generate_json_schema(derived_type: ast.DerivedType) -> Result(String, Nil) {
  let schema = build_json_schema(derived_type.parsed_type)
  Ok(
    "const "
    <> string.lowercase(derived_type.parsed_type.name)
    <> "_schema = \""
    <> escape_gleam_string(schema)
    <> "\"",
  )
}
```

The output of this function is the same input that has a new string with a json
schema embedded in it:

```gleam
/// A simple user type
/// !derived(json_schema)
pub type User {
  /// A regular user account
  User(name: String, age: Int, email: String)
  /// An admin user account
  Admin(name: String, permissions: List(String))
}

// ---- BEGIN DERIVED json_schema for User DO NOT MODIFY ---- //
const user_schema = "{
  \"type\": \"object\",
  \"title\": \"User\",
  \"oneOf\": [
    {
      \"type\": \"object\",
      \"title\": \"User\",
      \"description\": \"A regular user account\",
      \"properties\": {
        \"type\": { \"const\": \"User\" },
        \"name\": { \"type\": \"string\" },
        \"age\": { \"type\": \"integer\" },
        \"email\": { \"type\": \"string\" }
      },
      \"required\": [\"type\", \"name\", \"age\", \"email\"]
    },
    {
      \"type\": \"object\",
      \"title\": \"Admin\",
      \"description\": \"An admin user account\",
      \"properties\": {
        \"type\": { \"const\": \"Admin\" },
        \"name\": { \"type\": \"string\" },
        \"permissions\": { \"type\": \"array\", \"items\": { \"type\": \"string\" } }
      },
      \"required\": [\"type\", \"name\", \"permissions\"]
    }
  ]
}"
// ---- END DERIVED json_schema for User //
```

### Basic Parsing

If you need more control over what happens after the AST has been parsed, you
can use the `parse` function, which returns a list of DerivedType records that
you can introspect as you see fit:

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

Anywhere you want to generate code based on types. Some ideas I've had:

- Generating serializers and deserializers to various formats.
- Generating a [glint](https://hexdocs.pm/glint/index.html) CLI parser based
  solely on an input type.
- Generating schemas for various protocols.
- Generating stubs for wisp handlers or lustre clients
- Generating specialty hashing functions
