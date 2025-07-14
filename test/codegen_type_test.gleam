import codegen_type
import gleam/option
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
  // parse_single_variant_with_explicit_empty_parens_test()
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

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(5, 89),
        " A real codegen type! !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [codegen_type.Variant("Foo", "", [], [])]),
        "foobar",
      ),
    ]
}

pub fn parse_single_empty_variant_with_docstring_test() {
  let custom_types =
    "
    /// A real codegen type!
    /// !codegen_type(foobar)
    type Foo {
      /// A Foo does foo things
      Foo
    }
    "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(5, 121),
        " A real codegen type! !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant("Foo", " A Foo does foo things", [], []),
        ]),
        "foobar",
      ),
    ]
}

pub fn parse_multiple_empty_variants_with_docstring_test() {
  let custom_types =
    "
    /// A real codegen type!
    /// !codegen_type(foobar)
    type Foo {
      /// A Foo does foo things
      Foo
      /// A Bar does bar things
      Bar
    }
    "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(5, 163),
        " A real codegen type! !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant("Foo", " A Foo does foo things", [], []),
          codegen_type.Variant("Bar", " A Bar does bar things", [], []),
        ]),
        "foobar",
      ),
    ]
}

// This test is for legal gleam syntax that shouldn't normally happen becaues
// the formatter would remove the parens
pub fn parse_single_variant_with_explicit_empty_parens_test() {
  let custom_types =
    "
    /// !codegen_type(foobar)
    type Foo {
      Foo()
    }
    "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(5, 62),
        " !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [codegen_type.Variant("Foo", "", [], [])]),
        "foobar",
      ),
    ]
}

pub fn parse_variant_with_unlabellled_field_test() {
  let custom_types =
    "
    /// !codegen_type(foobar)
    type Foo {
      /// A Foo does foo things
      Foo(String)
    }
    "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(5, 100),
        " !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant(
            "Foo",
            " A Foo does foo things",
            [
              codegen_type.UnlabelledField(
                codegen_type.NamedType("String", option.None, []),
              ),
            ],
            [],
          ),
        ]),
        "foobar",
      ),
    ]
}

pub fn parse_variant_with_multiple_unlabellled_field_test() {
  let custom_types =
    "
    /// !codegen_type(foobar)
    type Foo {
      /// A Foo does foo things
      Foo(String, Int, Bool)
    }
    "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(5, 111),
        " !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant(
            "Foo",
            " A Foo does foo things",
            [
              codegen_type.UnlabelledField(
                codegen_type.NamedType("String", option.None, []),
              ),
              codegen_type.UnlabelledField(
                codegen_type.NamedType("Int", option.None, []),
              ),
              codegen_type.UnlabelledField(
                codegen_type.NamedType("Bool", option.None, []),
              ),
            ],
            [],
          ),
        ]),
        "foobar",
      ),
    ]
}

pub fn parse_type_with_generic_parameters_test() {
  todo
}

pub fn parse_type_with_attributes_test() {
  todo
}
