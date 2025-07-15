import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option}
import gleam/regexp
import gleam/result
import glexer
import glexer/token

/// Extract any custom types marked with !derived() from the input string
/// including their docstrings.
///
/// All other syntaxes (including invalid syntaxes) are ignored
pub fn parse(input: String) -> List(DerivedType) {
  input
  |> glexer.new()
  |> glexer.discard_whitespace()
  |> glexer.lex()
  |> parse_loop([])
  |> list.reverse
}

pub type ParseError {
  /// Encountered an unexpected token while parsing a derived type
  UnexpectedToken
  /// Encountered an unexpected token in a place where unknown tokens
  /// are expected (e.g. while parsing a function)
  IgnoredToken
}

pub type DerivedType {
  DerivedType(
    span: #(Int, Int),
    docstring: String,
    attributes: List(Attribute),
    publicity: Publicity,
    opaque_: Bool,
    parsed_type: Type,
    derived_module: String,
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
  Deprecated(reason: String)
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
  derived_types: List(DerivedType),
) -> List(DerivedType) {
  case tokens {
    [#(token.CommentDoc(docstring), start), ..tokens] -> {
      let #(tokens, docstring) = parse_docstring(tokens, docstring)
      case parse_documented_if_derived_type(tokens, docstring, start) {
        Ok(TokenResponse(tokens, custom_type)) ->
          parse_loop(tokens, list.prepend(derived_types, custom_type))
        Error(TokenResponse(tokens, IgnoredToken)) ->
          parse_loop(tokens, derived_types)
        Error(TokenResponse([], UnexpectedToken)) -> {
          io.println("Warning: Encountered unexpected end of file")
          derived_types
        }
        Error(TokenResponse([#(token, position), ..], UnexpectedToken)) -> {
          io.println(
            "Encountered unexpected token: "
            <> glexer.to_source([#(token, position)])
            <> " at byte offset "
            <> position.byte_offset |> int.to_string,
          )
          derived_types
        }
      }
    }
    [_, ..tokens] -> parse_loop(tokens, derived_types)
    [] -> derived_types
  }
}

/// Parse a documented entity, returning it only if the wrapped entity is a custom type
/// with a !derived() entry.
fn parse_documented_if_derived_type(
  tokens: List(PositionToken),
  docstring: String,
  docstring_start: glexer.Position,
) -> ParseResult(DerivedType) {
  case extract_derived_module(docstring) {
    Ok(derived_module) ->
      maybe_parse_derived_type(
        tokens,
        docstring,
        docstring_start,
        derived_module,
        [],
        Private,
        False,
      )
    Error(Nil) -> Error(TokenResponse(tokens, IgnoredToken))
  }
}

/// Parse an entity that may be a CustomType or may be something else
fn maybe_parse_derived_type(
  tokens: List(PositionToken),
  docstring: String,
  docstring_start: glexer.Position,
  derived_module: String,
  attributes: List(Attribute),
  publicity: Publicity,
  opaque_: Bool,
) -> ParseResult(DerivedType) {
  case tokens {
    [#(token.At, _), ..tokens] -> {
      use TokenResponse(tokens, attribute) <- result.try(parse_attribute(tokens))
      maybe_parse_derived_type(
        tokens,
        docstring,
        docstring_start,
        derived_module,
        [attribute, ..attributes],
        publicity,
        opaque_,
      )
    }
    [#(token.Pub, _), ..tokens] -> {
      maybe_parse_derived_type(
        tokens,
        docstring,
        docstring_start,
        derived_module,
        attributes,
        Public,
        opaque_,
      )
    }
    [#(token.Opaque, _), ..tokens] -> {
      maybe_parse_derived_type(
        tokens,
        docstring,
        docstring_start,
        derived_module,
        attributes,
        publicity,
        True,
      )
    }
    [#(token.Type, _), ..tokens] -> {
      parse_type(tokens)
      |> map_parse_result(fn(type_and_pos) {
        let #(parsed_type, end_pos) = type_and_pos
        DerivedType(
          span: #(docstring_start.byte_offset, end_pos),
          docstring: docstring,
          attributes: attributes |> list.reverse,
          publicity:,
          opaque_:,
          parsed_type:,
          derived_module:,
        )
      })
    }
    _ -> Error(TokenResponse(tokens, IgnoredToken))
  }
}

fn parse_type(tokens: List(PositionToken)) -> ParseResult(#(Type, Int)) {
  case tokens {
    [#(token.UpperName(name), _), #(token.LeftParen, _), ..tokens] -> {
      use TokenResponse(tokens, parameters) <- result.try(
        parse_type_parameter_names(tokens, []),
      )
      use TokenResponse(tokens, #(parsed_variants, end_pos)) <- result.try(
        parse_variants(tokens, []),
      )
      Ok(
        TokenResponse(tokens, #(
          Type(
            name,
            parameters |> list.reverse,
            parsed_variants |> list.reverse,
          ),
          end_pos,
        )),
      )
    }
    [#(token.UpperName(name), _), ..tokens] -> {
      parse_variants(tokens, [])
      |> map_parse_result(fn(variants_and_pos) {
        let #(parsed_variants, end_pos) = variants_and_pos
        #(Type(name, [], parsed_variants |> list.reverse), end_pos)
      })
    }
    tokens -> Error(TokenResponse(tokens, UnexpectedToken))
  }
}

fn parse_variants(
  tokens: List(PositionToken),
  reversed_variants: List(Variant),
) -> ParseResult(#(List(Variant), Int)) {
  case tokens {
    [#(token.LeftBrace, _), ..tokens] ->
      parse_variants(tokens, reversed_variants)
    [#(token.RightBrace, position), ..tokens] ->
      Ok(TokenResponse(tokens, #(reversed_variants, position.byte_offset)))
    tokens -> {
      use TokenResponse(tokens, variant) <- result.try(
        parse_maybe_documented_variant(tokens),
      )
      parse_variants(tokens, [variant, ..reversed_variants])
    }
  }
}

fn parse_maybe_documented_variant(
  tokens: List(PositionToken),
) -> ParseResult(Variant) {
  case tokens {
    [#(token.At, _), ..] -> parse_variant_definition(tokens, "", [])
    [#(token.UpperName(_), _), ..] -> parse_variant(tokens, "", [])
    [#(token.CommentDoc(docstring), _), ..tokens] -> {
      let #(tokens, docstring) = parse_docstring(tokens, docstring)
      parse_variant_definition(tokens, docstring, [])
    }
    _ -> Error(TokenResponse(tokens, UnexpectedToken))
  }
}

fn parse_variant_definition(
  tokens: List(PositionToken),
  docstring: String,
  attributes: List(Attribute),
) -> ParseResult(Variant) {
  case tokens {
    [#(token.At, _), ..tokens] -> {
      use TokenResponse(tokens, attribute) <- result.try(parse_attribute(tokens))
      parse_variant_definition(tokens, docstring, [attribute, ..attributes])
    }
    tokens -> parse_variant(tokens, docstring, attributes |> list.reverse)
  }
}

fn parse_variant(
  tokens: List(PositionToken),
  docstring: String,
  attributes: List(Attribute),
) -> ParseResult(Variant) {
  case tokens {
    [#(token.UpperName(name), _), #(token.LeftParen, _), ..tokens] -> {
      parse_fields(tokens, [])
      |> map_parse_result(fn(reversed_fields) {
        Variant(
          name: name,
          docstring: docstring,
          fields: reversed_fields |> list.reverse,
          attributes: attributes,
        )
      })
    }
    [#(token.UpperName(name), _), ..tokens] -> {
      Ok(TokenResponse(
        tokens,
        Variant(name:, docstring:, fields: [], attributes:),
      ))
    }
    _ -> Error(TokenResponse(tokens, UnexpectedToken))
  }
}

fn parse_fields(
  tokens: List(PositionToken),
  reversed_fields: List(Field),
) -> ParseResult(List(Field)) {
  case tokens {
    [#(token.RightParen, _), ..tokens] -> {
      Ok(TokenResponse(tokens, reversed_fields))
    }
    [#(token.Comma, _), ..tokens] -> {
      parse_fields(tokens, reversed_fields)
    }
    tokens -> {
      case parse_field(tokens) {
        Ok(TokenResponse(tokens, field)) ->
          parse_fields(tokens, [field, ..reversed_fields])
        Error(TokenResponse(tokens, IgnoredToken)) ->
          parse_fields(tokens, reversed_fields)
        Error(real_error) -> Error(real_error)
      }
    }
  }
}

fn parse_field(tokens: List(PositionToken)) -> ParseResult(Field) {
  case tokens {
    [#(token.RightParen, _), ..tokens] ->
      Error(TokenResponse(tokens, IgnoredToken))
    [#(token.Name(label), _), #(token.Colon, _), ..tokens] -> {
      parse_field_type(tokens)
      |> map_parse_result(LabelledField(_, label))
    }

    tokens -> {
      parse_field_type(tokens)
      |> map_parse_result(UnlabelledField)
    }
  }
}

fn parse_field_type(tokens: List(PositionToken)) -> ParseResult(FieldType) {
  case tokens {
    [#(token.UpperName(name), _), #(token.LeftParen, _), ..tokens] -> {
      use TokenResponse(tokens, parameters) <- result.try(
        parse_type_parameters(tokens, []),
      )
      Ok(TokenResponse(
        tokens,
        NamedType(name, option.None, parameters |> list.reverse),
      ))
    }
    [#(token.UpperName(name), _), ..tokens] ->
      Ok(TokenResponse(tokens, NamedType(name, option.None, [])))
    [#(token.Hash, _), #(token.LeftParen, _), ..tokens] -> {
      use TokenResponse(tokens, tuple_elements) <- result.try(
        parse_tuple_elements(tokens, []),
      )
      Ok(TokenResponse(tokens, TupleType(tuple_elements |> list.reverse)))
    }
    [#(token.Fn, _), #(token.LeftParen, _), ..tokens] -> {
      use TokenResponse(tokens, parameters) <- result.try(
        parse_function_parameters(tokens, []),
      )
      case tokens {
        [#(token.RightArrow, _), ..tokens] -> {
          use TokenResponse(tokens, return_type) <- result.try(parse_field_type(
            tokens,
          ))
          Ok(TokenResponse(
            tokens,
            FunctionType(parameters |> list.reverse, return_type),
          ))
        }
        _ -> Error(TokenResponse(tokens, UnexpectedToken))
      }
    }
    [
      #(token.Name(module), _),
      #(token.Dot, _),
      #(token.UpperName(name), _),
      #(token.LeftParen, _),
      ..tokens
    ] -> {
      use TokenResponse(tokens, parameters) <- result.try(
        parse_type_parameters(tokens, []),
      )
      Ok(TokenResponse(
        tokens,
        NamedType(name, option.Some(module), parameters |> list.reverse),
      ))
    }
    [
      #(token.Name(module), _),
      #(token.Dot, _),
      #(token.UpperName(name), _),
      ..tokens
    ] -> Ok(TokenResponse(tokens, NamedType(name, option.Some(module), [])))
    [#(token.Comma, _), ..tokens] -> Error(TokenResponse(tokens, IgnoredToken))
    [#(token.Name(variable_name), _), ..tokens] ->
      Ok(TokenResponse(tokens, VariableType(variable_name)))
    tokens -> Error(TokenResponse(tokens, UnexpectedToken))
  }
}

fn parse_tuple_elements(
  tokens: List(PositionToken),
  reversed_elements: List(FieldType),
) -> ParseResult(List(FieldType)) {
  parse_comma_separated(
    tokens,
    token.RightParen,
    parse_field_type,
    reversed_elements,
  )
}

fn parse_function_parameters(
  tokens: List(PositionToken),
  reversed_parameters: List(FieldType),
) -> ParseResult(List(FieldType)) {
  parse_comma_separated(
    tokens,
    token.RightParen,
    parse_field_type,
    reversed_parameters,
  )
}

fn parse_type_parameters(
  tokens: List(PositionToken),
  reversed_parameters: List(FieldType),
) -> ParseResult(List(FieldType)) {
  parse_comma_separated(
    tokens,
    token.RightParen,
    parse_field_type,
    reversed_parameters,
  )
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

fn parse_type_parameter_names(
  tokens: List(PositionToken),
  reversed_parameters: List(String),
) -> ParseResult(List(String)) {
  parse_comma_separated(
    tokens,
    token.RightParen,
    parse_parameter_name,
    reversed_parameters,
  )
}

fn parse_parameter_name(tokens: List(PositionToken)) -> ParseResult(String) {
  case tokens {
    [#(token.Name(name), _), ..tokens] -> Ok(TokenResponse(tokens, name))
    tokens -> Error(TokenResponse(tokens, UnexpectedToken))
  }
}

fn parse_attribute(tokens: List(PositionToken)) -> ParseResult(Attribute) {
  case tokens {
    [
      #(token.Name("deprecated"), _),
      #(token.LeftParen, _),
      #(token.String(reason), _),
      #(token.RightParen, _),
      ..tokens
    ] -> Ok(TokenResponse(tokens, Deprecated(reason)))
    [#(token.Name("internal"), _), ..tokens] ->
      Ok(TokenResponse(tokens, Internal))
    [
      #(token.Name("target"), _),
      #(token.LeftParen, _),
      #(token.Name(target), _),
      #(token.RightParen, _),
      ..tokens
    ] -> {
      case target {
        "erlang" -> Ok(TokenResponse(tokens, Target(Erlang)))
        "javascript" -> Ok(TokenResponse(tokens, Target(Javascript)))
        _ -> Error(TokenResponse(tokens, UnexpectedToken))
      }
    }
    tokens -> Error(TokenResponse(tokens, UnexpectedToken))
  }
}

fn parse_comma_separated(
  tokens: List(PositionToken),
  terminator: token.Token,
  parser: fn(List(PositionToken)) -> ParseResult(a),
  reversed_items: List(a),
) -> ParseResult(List(a)) {
  case tokens {
    [#(tok, _), ..tokens] if tok == terminator -> {
      Ok(TokenResponse(tokens, reversed_items))
    }
    [#(token.Comma, _), ..tokens] -> {
      parse_comma_separated(tokens, terminator, parser, reversed_items)
    }
    tokens -> {
      use TokenResponse(tokens, item) <- result.try(parser(tokens))
      parse_comma_separated(tokens, terminator, parser, [item, ..reversed_items])
    }
  }
}

type PositionToken =
  #(token.Token, glexer.Position)

type TokenResponse(response) {
  TokenResponse(tokens: List(PositionToken), response: response)
}

type ParseResult(value) =
  Result(TokenResponse(value), TokenResponse(ParseError))

fn map_parse_result(
  result: ParseResult(a),
  mapper: fn(a) -> b,
) -> ParseResult(b) {
  use TokenResponse(tokens, value) <- result.try(result)
  Ok(TokenResponse(tokens, mapper(value)))
}

/// Return the module inside parens in a magic !derived(return/this)
/// substring of the string. If the magic string occurs multiple times,
/// return the *last* instance (closest to the definition below the docstring)
fn extract_derived_module(string: String) -> Result(String, Nil) {
  let assert Ok(re) = regexp.from_string("!derived\\(([a-z][a-z_/]*)\\)\\s*$")

  let matches = regexp.scan(re, string) |> list.reverse

  case matches {
    [regexp.Match(_, [option.Some(name)]), ..] -> Ok(name)
    [] -> Error(Nil)
    _ ->
      panic as {
        "Unexpected regexp match parsing " <> string <> " for !derived"
      }
  }
}
