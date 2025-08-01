import derived/ast
import gleam/list
import gleam/regexp
import gleam/result
import gleam/string

pub type GenerateError(a) {
  ParseError(ast.ParseError)
  GenerationError(a)
}

pub fn parse(input: String) -> Result(List(ast.DerivedType), ast.ParseError) {
  ast.parse(input)
}

pub fn generate(
  input: String,
  derived_name: String,
  callback: fn(ast.DerivedType) -> Result(String, a),
) -> Result(String, GenerateError(a)) {
  use derived_types <- result.try(parse(input) |> result.map_error(ParseError))
  let filtered_types =
    derived_types
    |> list.filter(fn(derived_type) {
      derived_type.derived_names |> list.contains(derived_name)
    })
    |> list.reverse

  list.fold_until(filtered_types, Ok(input), fn(current, derived_type) {
    // safe because fold_until stops if it is an error
    let assert Ok(source) = current
    case callback(derived_type) {
      Ok(generated_section) ->
        list.Continue(
          Ok(create_derived_content(
            generated_section,
            derived_name,
            source,
            derived_type,
          )),
        )
      Error(error) -> list.Stop(Error(GenerationError(error)))
    }
  })
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

  find_and_replace_markers(
    source,
    derived_name,
    derived_type.parsed_type.name,
    new_content,
  )
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
    start_marker(derived_name, type_name)
    <> "[\\s\\S]*?"
    <> end_marker(derived_name, type_name)

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
  "// ---- BEGIN DERIVED "
  <> derived_name
  <> " for "
  <> type_name
  <> " DO NOT MODIFY ---- //"
}

fn end_marker(derived_name: String, type_name: String) -> String {
  "// ---- END DERIVED " <> derived_name <> " for " <> type_name <> " //"
}
