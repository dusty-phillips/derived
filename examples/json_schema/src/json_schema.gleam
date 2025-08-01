import derived
import derived/ast
import gleam/io
import gleam/list
import gleam/string

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

fn build_json_schema(type_def: ast.Type) -> String {
  let variant_schemas = list.map(type_def.variants, build_variant_schema)
  let variants_str = string.join(variant_schemas, ",\n    ")

  "{\n  \"type\": \"object\",\n  \"title\": \""
  <> type_def.name
  <> "\",\n  \"oneOf\": [\n    "
  <> variants_str
  <> "\n  ]\n}"
}

fn build_variant_schema(variant: ast.Variant) -> String {
  let description = add_description(variant.docstring)

  case variant.fields {
    [] -> {
      "{\n      \"type\": \"object\",\n      \"title\": \""
      <> variant.name
      <> "\""
      <> description
      <> ",\n      \"properties\": {\n        \"type\": { \"const\": \""
      <> variant.name
      <> "\" }\n      },\n      \"required\": [\"type\"]\n    }"
    }
    fields -> {
      let properties = list.map(fields, build_field_schema)
      let properties_str = string.join(properties, ",\n        ")
      let required_fields = get_required_fields(fields)
      let required_str = string.join(required_fields, "\", \"")

      "{\n      \"type\": \"object\",\n      \"title\": \""
      <> variant.name
      <> "\""
      <> description
      <> ",\n      \"properties\": {\n        \"type\": { \"const\": \""
      <> variant.name
      <> "\" },\n        "
      <> properties_str
      <> "\n      },\n      \"required\": [\"type\", \""
      <> required_str
      <> "\"]\n    }"
    }
  }
}

fn build_field_schema(field: ast.Field) -> String {
  case field {
    ast.LabelledField(field_type, label) -> {
      "\"" <> label <> "\": " <> build_field_type_schema(field_type)
    }
    ast.UnlabelledField(_) -> {
      // For unlabelled fields, we'd need to generate positional property names
      // This is a simplified implementation
      "\"value\": " <> build_field_type_schema(field.field_type)
    }
  }
}

fn build_field_type_schema(field_type: ast.FieldType) -> String {
  case field_type {
    ast.NamedType("String", _, _) -> "{ \"type\": \"string\" }"
    ast.NamedType("Int", _, _) -> "{ \"type\": \"integer\" }"
    ast.NamedType("Float", _, _) -> "{ \"type\": \"number\" }"
    ast.NamedType("Bool", _, _) -> "{ \"type\": \"boolean\" }"
    ast.NamedType("List", _, [inner_type]) -> {
      "{ \"type\": \"array\", \"items\": "
      <> build_field_type_schema(inner_type)
      <> " }"
    }
    ast.NamedType(name, _, _) -> {
      "{ \"$ref\": \"#/definitions/" <> name <> "\" }"
    }
    ast.TupleType(elements) -> {
      let element_schemas = list.map(elements, build_field_type_schema)
      let elements_str = string.join(element_schemas, ", ")
      "{ \"type\": \"array\", \"items\": [" <> elements_str <> "] }"
    }
    ast.VariableType(_) -> "{ \"type\": \"object\" }"
    ast.FunctionType(_, _) -> "{ \"type\": \"object\" }"
  }
}

fn get_required_fields(fields: List(ast.Field)) -> List(String) {
  list.filter_map(fields, fn(field) {
    case field {
      ast.LabelledField(_, label) -> Ok(label)
      ast.UnlabelledField(_) -> Error(Nil)
    }
  })
}

fn escape_json_string(input: String) -> String {
  input
  |> string.replace("\\", "\\\\")
  |> string.replace("\"", "\\\"")
  |> string.replace("\n", "\\n")
  |> string.replace("\r", "\\r")
  |> string.replace("\t", "\\t")
}

fn escape_gleam_string(input: String) -> String {
  input
  |> string.replace("\\", "\\\\")
  |> string.replace("\"", "\\\"")
}

fn add_description(docstring: String) -> String {
  case string.trim(docstring) {
    "" -> ""
    trimmed ->
      ",\n      \"description\": \"" <> escape_json_string(trimmed) <> "\""
  }
}
