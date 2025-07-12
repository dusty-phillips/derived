import codegen_type
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn ignore_undocumented_tokens_test() {
  let custom_types =
    "import gleam/io

  pub type Foo {
    Foo(bar: String)
  }

  fn do() {
    io.println(\"doing\")
  }
"
    |> codegen_type.parse

  assert custom_types == []
}

pub fn ignore_unteathered_docstring_test() {
  let custom_types =
    "
    /// this is a docstring
    /// of many lines
    /// but it doesn't contain the codgen_type magic string
    "
    |> codegen_type.parse

  assert custom_types == []
}

pub fn ignore_docstring_with_function_test() {
  let custom_types =
    "
    /// this is a docstring
    /// of many lines
    /// attached to a function
    fn some_function() {
    }
    "
    |> codegen_type.parse

  assert custom_types == []
}

pub fn ignore_codegen_docstring_with_function_test() {
  let custom_types =
    "
    /// this is a docstring
    /// of many lines
    /// attached to a function
    /// !codegen_type(foobar)
    fn some_function() {
    }
    "
    |> codegen_type.parse

  assert custom_types == []
}

pub fn parse_empty_private_codegen_type_test() {
  let custom_types =
    "
    /// A real codegen type!
    /// !codegen_type(foobar)
    type Foo {}
    "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(5, 74),
        " A real codegen type! !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], []),
        "foobar",
      ),
    ]
}

pub fn parse_single_empty_variant_codegen_type_test() {
  let custom_types =
    "
    /// A real codegen type!
    /// !codegen_type(foobar)
    type Foo {
      Foo
    }
    "
    |> codegen_type.parse

  assert custom_types == []
}

pub fn parse_type_with_parameters_test() {
  todo
}

pub fn parse_type_with_attributes_test() {
  todo
}
