import derived/ast
import gleam/list
import gleam/regexp
import gleam/result
import gleam/string

pub fn parse(input: String) {
  ast.parse(input)
}

pub fn generate(
  input: String,
  derived_name: String,
  callback: fn(ast.DerivedType) -> Result(String, Nil),
) -> String {
  let derived_types =
    input
    |> parse
    |> list.filter(fn(derived_type) {
      derived_type.derived_names |> list.contains(derived_name)
    })
    |> list.reverse

  use modified_source, derived_type <- list.fold(derived_types, input)

  derived_type
  |> callback
  |> result.map(create_derived_content(
    _,
    derived_name,
    modified_source,
    derived_type,
  ))
  |> result.unwrap(modified_source)
}

fn create_derived_content(
  generated_code: String,
  derived_name: String,
  source: String,
  derived_type: ast.DerivedType,
) -> String {
  let new_content =
    start_marker(derived_name, derived_type.parsed_type.name)
    <> "\n"
    <> generated_code
    <> "\n"
    <> end_marker(derived_name, derived_type.parsed_type.name)

  find_and_replace_markers(source, derived_name, derived_type.parsed_type.name, new_content)
  |> result.lazy_unwrap(fn() {
    insert_after_type(source, derived_type, new_content)
  })
}

fn find_and_replace_markers(
  source: String,
  derived_name: String,
  type_name: String,
  new_content: String,
) -> Result(String, Nil) {
  let pattern =
    start_marker(derived_name, type_name) <> "[\\s\\S]*?" <> end_marker(derived_name, type_name)

  case
    regexp.compile(
      pattern,
      regexp.Options(case_insensitive: False, multi_line: True),
    )
  {
    Ok(regex) -> {
      case regexp.replace(regex, source, new_content) {
        result if result != source -> Ok(result)
        _ -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
  }
}

fn insert_after_type(
  source: String,
  derived_type: ast.DerivedType,
  content: String,
) -> String {
  let #(_start, end) = derived_type.span
  let before = string.slice(source, 0, end + 1)
  let after = string.slice(source, end + 1, string.length(source) - end - 1)

  before <> "\n\n" <> content <> after
}

fn start_marker(derived_name: String, type_name: String) -> String {
  "// ---- BEGIN DERIVED " <> derived_name <> " for " <> type_name <> " DO NOT MODIFY ---- //"
}

fn end_marker(derived_name: String, type_name: String) -> String {
  "// ---- END DERIVED " <> derived_name <> " for " <> type_name <> " //"
}
