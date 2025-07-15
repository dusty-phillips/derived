# derived

[![Package Version](https://img.shields.io/hexpm/v/derived)](https://hex.pm/packages/derived)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/derived/)

A Gleam library for parsing custom types from Gleam source code that are marked with special `!derived()` annotations in their docstrings.

```sh
gleam add derived@1
```
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

Further documentation can be found at <https://hexdocs.pm/derived>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
