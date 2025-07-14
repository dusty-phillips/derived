import glance
import gleam/list
import gleam/option.{type Option}
import gleam/regexp
import gleam/result
import glexer
import glexer/token

/// Extract any custom types marked with !codegen_type() from the input string
/// including their docstrings.
///
/// All other syntaxes (including invalid syntaxes) are ignored
pub fn parse(input: String) -> List(CodegenType) {
  input |> glance.module() |> echo

  input
  |> glexer.new()
  |> glexer.discard_whitespace()
  |> glexer.lex()
  |> echo
  |> parse_loop([])
  |> list.reverse
}

pub type CodegenType {
  CodegenType(
    span: #(Int, Int),
    docstring: String,
    attributes: List(Attribute),
    publicity: Publicity,
    opaque_: Bool,
    parsed_type: Type,
    codegen_module: String,
  )
}

pub type Type {
  Type(name: String, parameters: List(String), variants: List(Variant))
}

pub type Publicity {
  Public
  Private
}

pub type Variant {
  Variant(
    name: String,
    docstring: String,
    fields: List(Field),
    attributes: List(Attribute),
  )
}

pub type Field {
  LabelledField(field_type: FieldType, label: String)
  UnlabelledField(field_type: FieldType)
}

pub type Attribute {
  Target(target: Target)
  Deprecated
  Internal
}

pub type Target {
  Erlang
  Javascript
}

pub type FieldType {
  NamedType(name: String, module: Option(String), parameters: List(FieldType))
  TupleType(elements: List(FieldType))
  FunctionType(parameters: List(FieldType), return: FieldType)
  VariableType(name: String)
}

fn parse_loop(
  tokens: List(PositionToken),
  codegen_types: List(CodegenType),
) -> List(CodegenType) {
  case tokens {
    [#(token.CommentDoc(docstring), start), ..tokens] -> {
      let #(tokens, docstring) = parse_docstring(tokens, docstring)
      case parse_documented_if_codegen_type(tokens, docstring, start) {
        Error(tokens) -> parse_loop(tokens, codegen_types)
        Ok(#(tokens, custom_type)) ->
          parse_loop(tokens, list.prepend(codegen_types, custom_type))
      }
    }
    [_, ..tokens] -> parse_loop(tokens, codegen_types)
    [] -> codegen_types
  }
}

/// Parse a documented entity, returning it only if the wrapped entity is a custom type
/// with a !codegen_type() entry.
fn parse_documented_if_codegen_type(
  tokens: List(PositionToken),
  docstring: String,
  docstring_start: glexer.Position,
) -> ParseResult(CodegenType) {
  case extract_codegen_module(docstring) {
    Ok(codegen_module) ->
      maybe_parse_codegen_type(
        tokens,
        docstring,
        docstring_start,
        codegen_module,
      )
    Error(Nil) -> Error(tokens)
  }
}

/// Parse an entity that may be a CustomType or may be something else
fn maybe_parse_codegen_type(
  tokens: List(PositionToken),
  docstring: String,
  docstring_start: glexer.Position,
  codegen_module: String,
) -> ParseResult(CodegenType) {
  case tokens {
    [#(token.Type, _), ..tokens] -> {
      use #(tokens, #(parsed_type, end_pos)) <- result.try(parse_type(tokens))
      Ok(#(
        tokens,
        CodegenType(
          span: #(docstring_start.byte_offset, end_pos),
          docstring: docstring,
          attributes: [],
          publicity: Private,
          opaque_: False,
          parsed_type:,
          codegen_module:,
        ),
      ))
    }
    _ -> Error(tokens)
  }
}

fn parse_type(tokens: List(PositionToken)) -> ParseResult(#(Type, Int)) {
  case tokens {
    [#(token.UpperName(name), _), #(token.LeftParen, _), ..tokens] -> todo
    [#(token.UpperName(name), _), #(token.LeftBrace, _), ..tokens] -> {
      use #(tokens, #(parsed_variants, end_pos)) <- result.try(
        parse_variants(tokens, []),
      )
      Ok(#(tokens, #(Type(name, [], parsed_variants |> list.reverse), end_pos)))
    }
    tokens -> Error(tokens)
  }
}

fn parse_variants(
  tokens: List(PositionToken),
  reversed_variants: List(Variant),
) -> ParseResult(#(List(Variant), Int)) {
  case tokens {
    [#(token.RightBrace, position), ..tokens] ->
      Ok(#(tokens, #(reversed_variants, position.byte_offset)))
    tokens -> {
      use #(tokens, variant) <- result.try(parse_maybe_documented_variant(
        tokens,
      ))
      parse_variants(tokens, [variant, ..reversed_variants])
    }
  }
}

fn parse_maybe_documented_variant(
  tokens: List(PositionToken),
) -> ParseResult(Variant) {
  case tokens {
    [#(token.UpperName(_), _), ..] -> parse_variant(tokens, "")
    [#(token.CommentDoc(docstring), _), ..tokens] -> {
      let #(tokens, docstring) = parse_docstring(tokens, docstring)
      parse_variant_definition(tokens, docstring)
    }
    _ -> todo
  }
}

fn parse_variant_definition(
  tokens: List(PositionToken),
  docstring: String,
) -> ParseResult(Variant) {
  parse_variant(tokens, docstring)
}

fn parse_variant(
  tokens: List(PositionToken),
  docstring: String,
) -> ParseResult(Variant) {
  case tokens {
    [#(token.UpperName(name), _), #(token.LeftParen, _), ..tokens] -> {
      use #(tokens, reversed_fields) <- result.try(parse_fields(tokens, []))
      Ok(#(
        tokens,
        Variant(
          name:,
          docstring:,
          fields: reversed_fields |> list.reverse,
          attributes: [],
        ),
      ))
    }
    [#(token.UpperName(name), _), ..tokens] -> {
      Ok(#(tokens, Variant(name:, docstring:, fields: [], attributes: [])))
    }
    _ -> todo
  }
}

fn parse_fields(
  tokens: List(PositionToken),
  reversed_fields: List(Field),
) -> ParseResult(List(Field)) {
  case tokens {
    [#(token.RightParen, _), ..tokens] -> {
      Ok(#(tokens, reversed_fields))
    }
    [#(token.Comma, _), ..tokens] -> {
      parse_fields(tokens, reversed_fields)
    }
    tokens -> {
      case parse_field(tokens) {
        Error(tokens) -> parse_fields(tokens, reversed_fields)
        Ok(#(tokens, field)) -> parse_fields(tokens, [field, ..reversed_fields])
      }
    }
  }
}

fn parse_field(tokens: List(PositionToken)) -> ParseResult(Field) {
  case tokens {
    [#(token.UpperName(name), _), ..] ->
      case parse_field_type(tokens) {
        Ok(#(tokens, field_type)) -> Ok(#(tokens, UnlabelledField(field_type)))
        Error(tokens) -> Error(tokens)
      }
    tokens -> Error(tokens)
  }
}

fn parse_field_type(tokens: List(PositionToken)) -> ParseResult(FieldType) {
  case tokens {
    [#(token.UpperName(name), _), #(token.LeftParen, _), ..tokens] -> todo
    [#(token.UpperName(name), _), ..tokens] ->
      Ok(#(tokens, NamedType(name, option.None, [])))
    tokens -> Error(tokens)
  }
}

fn parse_docstring(
  tokens: List(PositionToken),
  docstring: String,
) -> #(List(PositionToken), String) {
  case tokens {
    [#(token.CommentDoc(new_docstring), _), ..tokens] ->
      parse_docstring(tokens, docstring <> new_docstring)
    tokens -> #(tokens, docstring)
  }
}

type PositionToken =
  #(token.Token, glexer.Position)

type ParseResult(value) =
  Result(#(List(PositionToken), value), List(PositionToken))

fn extract_codegen_module(string: String) -> Result(String, Nil) {
  let assert Ok(re) =
    regexp.from_string("!codegen_type\\(([a-z][a-z_/]*)\\)\\s*$")

  let matches = regexp.scan(re, string) |> list.reverse

  case matches {
    [regexp.Match(_, [option.Some(name)]), ..] -> Ok(name)
    [] -> Error(Nil)
    _ ->
      panic as {
        "Unexpected regexp match parsing " <> string <> " for !codegen_type"
      }
  }
}
