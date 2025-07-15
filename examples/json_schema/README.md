# JSON Schema Code Generation Example

This example demonstrates how to use the `derived` code generator to
automatically generate JSON schemas from Gleam types.

## What this example does

The example takes Gleam types marked with `!derived(json_schema)` directives in
their docstrings and generates corresponding JSON Schema definitions as const
strings.

## How it works

1. **Mark types for generation**: Add `!derived(json_schema)` to docstrings of
   types you want schemas for
2. **Run the generator**: The `derived.generate()` function finds all marked
   types and calls your generator function
3. Returned string will have generated json schema consts inserted into the source.

## Key example code

### Core Generator Function

```gleam
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

The generator:

1. Checks if the type has `json_schema` in its derived names
2. Builds a JSON schema from the parsed type structure
3. Returns a JavaScript constant declaration

### Input Gleam Types

```gleam
/// A simple user type
/// !derived(json_schema)
pub type User {
  /// A regular user account
  User(name: String, age: Int, email: String)
  /// An admin user account
  Admin(name: String, permissions: List(String))
}

/// A product in an e-commerce system
/// !derived(json_schema)
type Product {
  /// A physical product
  Physical(name: String, price: Float, weight: Float)
  /// A digital product
  Digital(name: String, price: Float, download_url: String)
}
```

### Generated Output

```javascript
const user_schema = {
  "type": "object",
  "title": "User",
  "oneOf": [
    {
      "type": "object",
      "title": "User",
      "description": "A regular user account",
      "properties": {
        "type": { "const": "User" },
        "name": { "type": "string" },
        "age": { "type": "integer" },
        "email": { "type": "string" }
      },
      "required": ["type", "name", "age", "email"]
    },
    {
      "type": "object",
      "title": "Admin",
      "description": "An admin user account",
      "properties": {
        "type": { "const": "Admin" },
        "name": { "type": "string" },
        "permissions": { "type": "array", "items": { "type": "string" } }
      },
      "required": ["type", "name", "permissions"]
    }
  ]
};
```

## How to run this example

```sh
gleam run
```

This will process the example types and output the generated JSON schemas to
the console.

## Implementation Details

The generator handles several Gleam type features:

### Basic Type Mapping

- `String` → `"type": "string"`
- `Int` → `"type": "integer"`
- `Float` → `"type": "number"`
- `Bool` → `"type": "boolean"`

### Complex Types

- `List(T)` → `"type": "array", "items": <T-schema>`
- `#(A, B)` → `"type": "array", "items": [<A-schema>, <B-schema>]`
- Custom types → `"$ref": "#/definitions/<TypeName>"`

### Tagged Unions

Gleam's custom types with multiple variants are converted to JSON Schema's
`oneOf` with discriminator fields:

- Each variant becomes a separate schema object
- A `"type"` field distinguishes between variants
- Labeled fields become object properties
- All fields are marked as required

## Project Structure

```
examples/json_schema/
├── README.md           # This file
├── gleam.toml         # Project configuration with derived dependency
├── src/
│   └── json_schema.gleam  # Main generator implementation
└── test/
    └── json_schema_test.gleam  # Tests (if any)
```

The `gleam.toml` uses a filesystem import to reference the parent `derived` library:

```toml
[dependencies]
derived = { path = "../../" }
```

This allows the example to use the library directly from the repository without
publishing it to Hex.
