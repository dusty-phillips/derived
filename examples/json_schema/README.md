# JSON Schema Code Generation Example

This example demonstrates how to use the `derived` code generator to
automatically generate JSON schemas from Gleam types.

## What this example does

The example takes Gleam types marked with `!derived(json_schema)` directives in
their docstrings and generates corresponding JSON Schema definitions as const
strings.

## How it works

1. **Mark types for generation**: Add `!derived(json_schema)` to docstrings of
   types you want schemas for.
2. **Run the generator**: The `derived.generate()` function finds all marked
   types and calls your generator function.
3. Returned string has generated json schema consts inserted into the source
   after the type.

Here is the key code generation code:

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

/// A product in an e-commerce system
/// !derived(json_schema)
type Product {
  /// A physical product
  Physical(name: String, price: Float, weight: Float)
  /// A digital product
  Digital(name: String, price: Float, download_url: String)
}
"

  let result =
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

Most of the `json_schema.gleam` file is in support of the `build_json_schema` function,
which performs arbitrary code generation work (in this case, creating a const string).
The output of the `generate` function is printed to the console and looks like this:

```gleam
//// A simple user type
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

/// A product in an e-commerce system
/// !derived(json_schema)
type Product {
  /// A physical product
  Physical(name: String, price: Float, weight: Float)
  /// A digital product
  Digital(name: String, price: Float, download_url: String)
}

// ---- BEGIN DERIVED json_schema for Product DO NOT MODIFY ---- //
const product_schema = "{
  \"type\": \"object\",
  \"title\": \"Product\",
  \"oneOf\": [
    {
      \"type\": \"object\",
      \"title\": \"Physical\",
      \"description\": \"A physical product\",
      \"properties\": {
        \"type\": { \"const\": \"Physical\" },
        \"name\": { \"type\": \"string\" },
        \"price\": { \"type\": \"number\" },
        \"weight\": { \"type\": \"number\" }
      },
      \"required\": [\"type\", \"name\", \"price\", \"weight\"]
    },
    {
      \"type\": \"object\",
      \"title\": \"Digital\",
      \"description\": \"A digital product\",
      \"properties\": {
        \"type\": { \"const\": \"Digital\" },
        \"name\": { \"type\": \"string\" },
        \"price\": { \"type\": \"number\" },
        \"download_url\": { \"type\": \"string\" }
      },
      \"required\": [\"type\", \"name\", \"price\", \"download_url\"]
    }
  ]
}"
// ---- END DERIVED json_schema for Product //
```
