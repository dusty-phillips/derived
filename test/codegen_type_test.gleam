import codegen_type
import gleam/option
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

pub fn parse_variant_with_multiple_labelled_field_test() {
  let custom_types =
    "
  /// !codegen_type(foobar)
  type Foo {
    Foo(bar: String, baz: Int)
  }
  "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(3, 75),
        " !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant(
            "Foo",
            "",
            [
              codegen_type.LabelledField(
                codegen_type.NamedType("String", option.None, []),
                "bar",
              ),
              codegen_type.LabelledField(
                codegen_type.NamedType("Int", option.None, []),
                "baz",
              ),
            ],
            [],
          ),
        ]),
        "foobar",
      ),
    ]
}

pub fn parse_variant_with_nested_tuple_field_test() {
  let custom_types =
    "
  /// !codegen_type(foobar)
  type Foo {
    Foo(#(Int, #(String, Bool)))
  }
  "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(3, 77),
        " !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant(
            "Foo",
            "",
            [
              codegen_type.UnlabelledField(
                codegen_type.TupleType([
                  codegen_type.NamedType("Int", option.None, []),
                  codegen_type.TupleType([
                    codegen_type.NamedType("String", option.None, []),
                    codegen_type.NamedType("Bool", option.None, []),
                  ]),
                ]),
              ),
            ],
            [],
          ),
        ]),
        "foobar",
      ),
    ]
}

pub fn parse_variant_with_parameterized_field_test() {
  let custom_types =
    "
  /// !codegen_type(foobar)
  type Foo {
    Foo(List(Int))
  }
  "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(3, 63),
        " !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant(
            "Foo",
            "",
            [
              codegen_type.UnlabelledField(
                codegen_type.NamedType("List", option.None, [
                  codegen_type.NamedType("Int", option.None, []),
                ]),
              ),
            ],
            [],
          ),
        ]),
        "foobar",
      ),
    ]
}

pub fn parse_variant_with_zero_parameter_function_test() {
  let custom_types =
    "
  /// !codegen_type(foobar)
  type Foo {
    Foo(fn() -> Int)
  }
  "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(3, 65),
        " !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant(
            "Foo",
            "",
            [
              codegen_type.UnlabelledField(codegen_type.FunctionType(
                [],
                codegen_type.NamedType("Int", option.None, []),
              )),
            ],
            [],
          ),
        ]),
        "foobar",
      ),
    ]
}

pub fn parse_variant_with_mixed_fields_test() {
  let custom_types =
    "
  /// !codegen_type(foobar)
  type Foo {
    Foo(String, bar: Int, Bool)
  }
  "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(3, 76),
        " !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant(
            "Foo",
            "",
            [
              codegen_type.UnlabelledField(
                codegen_type.NamedType("String", option.None, []),
              ),
              codegen_type.LabelledField(
                codegen_type.NamedType("Int", option.None, []),
                "bar",
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

pub fn parse_variant_with_module_qualified_parameterized_field_test() {
  let custom_types =
    "
  /// !codegen_type(foobar)
  type Foo {
    Foo(option.Option(String))
  }
  "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(3, 75),
        " !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant(
            "Foo",
            "",
            [
              codegen_type.UnlabelledField(
                codegen_type.NamedType("Option", option.Some("option"), [
                  codegen_type.NamedType("String", option.None, []),
                ]),
              ),
            ],
            [],
          ),
        ]),
        "foobar",
      ),
    ]
}

pub fn parse_multiple_variants_with_fields_test() {
  let custom_types =
    "
  /// !codegen_type(foobar)
  type Foo {
    /// Simple variant
    Bar
    /// Variant with field
    Baz(String)
    /// Complex variant
    Qux(name: String, List(Int))
  }
  "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(3, 175),
        " !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant("Bar", " Simple variant", [], []),
          codegen_type.Variant(
            "Baz",
            " Variant with field",
            [
              codegen_type.UnlabelledField(
                codegen_type.NamedType("String", option.None, []),
              ),
            ],
            [],
          ),
          codegen_type.Variant(
            "Qux",
            " Complex variant",
            [
              codegen_type.LabelledField(
                codegen_type.NamedType("String", option.None, []),
                "name",
              ),
              codegen_type.UnlabelledField(
                codegen_type.NamedType("List", option.None, [
                  codegen_type.NamedType("Int", option.None, []),
                ]),
              ),
            ],
            [],
          ),
        ]),
        "foobar",
      ),
    ]
}

pub fn parse_variant_with_function_taking_tuple_test() {
  let custom_types =
    "
  /// !codegen_type(foobar)
  type Foo {
    Foo(fn(#(Int, String)) -> Bool)
  }
  "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(3, 80),
        " !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant(
            "Foo",
            "",
            [
              codegen_type.UnlabelledField(codegen_type.FunctionType(
                [
                  codegen_type.TupleType([
                    codegen_type.NamedType("Int", option.None, []),
                    codegen_type.NamedType("String", option.None, []),
                  ]),
                ],
                codegen_type.NamedType("Bool", option.None, []),
              )),
            ],
            [],
          ),
        ]),
        "foobar",
      ),
    ]
}

pub fn parse_variant_with_tuple_containing_function_test() {
  let custom_types =
    "
  /// !codegen_type(foobar)
  type Foo {
    Foo(#(Int, fn() -> String))
  }
  "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(3, 76),
        " !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant(
            "Foo",
            "",
            [
              codegen_type.UnlabelledField(
                codegen_type.TupleType([
                  codegen_type.NamedType("Int", option.None, []),
                  codegen_type.FunctionType(
                    [],
                    codegen_type.NamedType("String", option.None, []),
                  ),
                ]),
              ),
            ],
            [],
          ),
        ]),
        "foobar",
      ),
    ]
}

pub fn parse_variant_with_complex_parameterized_types_test() {
  let custom_types =
    "
  /// !codegen_type(foobar)
  type Foo {
    Foo(Result(#(Int, String), List(Error)))
  }
  "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(3, 89),
        " !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant(
            "Foo",
            "",
            [
              codegen_type.UnlabelledField(
                codegen_type.NamedType("Result", option.None, [
                  codegen_type.TupleType([
                    codegen_type.NamedType("Int", option.None, []),
                    codegen_type.NamedType("String", option.None, []),
                  ]),
                  codegen_type.NamedType("List", option.None, [
                    codegen_type.NamedType("Error", option.None, []),
                  ]),
                ]),
              ),
            ],
            [],
          ),
        ]),
        "foobar",
      ),
    ]
}

pub fn parse_multiple_codegen_types_test() {
  let custom_types =
    "
  /// First type
  /// !codegen_type(module_a)
  type Foo {
    Foo(String)
  }

  /// Second type
  /// !codegen_type(module_b)
  type Bar {
    Bar(Int)
  }
  "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(3, 79),
        " First type !codegen_type(module_a)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [
          codegen_type.Variant(
            "Foo",
            "",
            [
              codegen_type.UnlabelledField(
                codegen_type.NamedType("String", option.None, []),
              ),
            ],
            [],
          ),
        ]),
        "module_a",
      ),
      codegen_type.CodegenType(
        #(84, 158),
        " Second type !codegen_type(module_b)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Bar", [], [
          codegen_type.Variant(
            "Bar",
            "",
            [
              codegen_type.UnlabelledField(
                codegen_type.NamedType("Int", option.None, []),
              ),
            ],
            [],
          ),
        ]),
        "module_b",
      ),
    ]
}

pub fn parse_docstring_with_multiple_codegen_annotations_test() {
  let custom_types =
    "
  /// This is a type with multiple annotations
  /// !codegen_type(first_module)
  /// More documentation here
  /// !codegen_type(second_module)
  type Foo {
    Foo
  }
  "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(3, 170),
        " This is a type with multiple annotations !codegen_type(first_module) More documentation here !codegen_type(second_module)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", [], [codegen_type.Variant("Foo", "", [], [])]),
        "second_module",
      ),
    ]
}

pub fn parse_parameterized_type_test() {
  let custom_types =
    "
  /// !codegen_type(foobar)
  type Foo(a) {
    Bar(a)
  }
  "
    |> codegen_type.parse

  assert custom_types
    == [
      codegen_type.CodegenType(
        #(3, 58),
        " !codegen_type(foobar)",
        [],
        codegen_type.Private,
        False,
        codegen_type.Type("Foo", ["a"], [
          codegen_type.Variant(
            "Bar",
            "",
            [codegen_type.UnlabelledField(codegen_type.VariableType("a"))],
            [],
          ),
        ]),
        "foobar",
      ),
    ]
}
