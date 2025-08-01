import derived/ast
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
    |> ast.parse

  assert custom_types == Ok([])
}

pub fn ignore_unteathered_docstring_test() {
  let custom_types =
    "
    /// this is a docstring
    /// of many lines
    /// but it doesn't contain the codgen_type magic string
    "
    |> ast.parse

  assert custom_types == Ok([])
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
    |> ast.parse

  assert custom_types == Ok([])
}

pub fn ignore_derived_with_function_test() {
  let custom_types =
    "
    /// this is a docstring
    /// of many lines
    /// attached to a function
    /// !derived(foobar)
    fn some_function() {
    }
    "
    |> ast.parse

  assert custom_types == Ok([])
}

pub fn parse_empty_private_derived_test() {
  let custom_types =
    "
    /// A real derived type!
    /// !derived(foobar)
    type Foo {}
    "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(5, 69),
        " A real derived type!\n !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], []),
        ["foobar"],
      ),
    ])
}

pub fn parse_single_empty_variant_derived_test() {
  let custom_types =
    "
    /// A real derived type!
    /// !derived(foobar)
    type Foo {
      Foo
    }
    "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(5, 84),
        " A real derived type!\n !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [ast.Variant("Foo", "", [], [])]),
        ["foobar"],
      ),
    ])
}

pub fn parse_single_empty_variant_with_docstring_test() {
  let custom_types =
    "
    /// A real derived type!
    /// !derived(foobar)
    type Foo {
      /// A Foo does foo things
      Foo
    }
    "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(5, 116),
        " A real derived type!\n !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant("Foo", " A Foo does foo things", [], []),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_multiple_empty_variants_with_docstring_test() {
  let custom_types =
    "
    /// A real derived type!
    /// !derived(foobar)
    type Foo {
      /// A Foo does foo things
      Foo
      /// A Bar does bar things
      Bar
    }
    "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(5, 158),
        " A real derived type!\n !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant("Foo", " A Foo does foo things", [], []),
          ast.Variant("Bar", " A Bar does bar things", [], []),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_variant_with_multiple_unlabellled_field_test() {
  let custom_types =
    "
    /// !derived(foobar)
    type Foo {
      /// A Foo does foo things
      Foo(String, Int, Bool)
    }
    "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(5, 106),
        " !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant(
            "Foo",
            " A Foo does foo things",
            [
              ast.UnlabelledField(ast.NamedType("String", option.None, [])),
              ast.UnlabelledField(ast.NamedType("Int", option.None, [])),
              ast.UnlabelledField(ast.NamedType("Bool", option.None, [])),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_variant_with_multiple_labelled_field_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(bar: String, baz: Int)
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 70),
        " !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant(
            "Foo",
            "",
            [
              ast.LabelledField(ast.NamedType("String", option.None, []), "bar"),
              ast.LabelledField(ast.NamedType("Int", option.None, []), "baz"),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_variant_with_nested_tuple_field_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(#(Int, #(String, Bool)))
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 72),
        " !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant(
            "Foo",
            "",
            [
              ast.UnlabelledField(
                ast.TupleType([
                  ast.NamedType("Int", option.None, []),
                  ast.TupleType([
                    ast.NamedType("String", option.None, []),
                    ast.NamedType("Bool", option.None, []),
                  ]),
                ]),
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_variant_with_parameterized_field_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(List(Int))
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 58),
        " !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant(
            "Foo",
            "",
            [
              ast.UnlabelledField(
                ast.NamedType("List", option.None, [
                  ast.NamedType("Int", option.None, []),
                ]),
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_variant_with_zero_parameter_function_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(fn() -> Int)
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 60),
        " !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant(
            "Foo",
            "",
            [
              ast.UnlabelledField(ast.FunctionType(
                [],
                ast.NamedType("Int", option.None, []),
              )),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_variant_with_mixed_fields_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(String, bar: Int, Bool)
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 71),
        " !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant(
            "Foo",
            "",
            [
              ast.UnlabelledField(ast.NamedType("String", option.None, [])),
              ast.LabelledField(ast.NamedType("Int", option.None, []), "bar"),
              ast.UnlabelledField(ast.NamedType("Bool", option.None, [])),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_variant_with_module_qualified_parameterized_field_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(option.Option(String))
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 70),
        " !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant(
            "Foo",
            "",
            [
              ast.UnlabelledField(
                ast.NamedType("Option", option.Some("option"), [
                  ast.NamedType("String", option.None, []),
                ]),
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_multiple_variants_with_fields_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    /// Simple variant
    Bar
    /// Variant with field
    Baz(String)
    /// Complex variant
    Qux(name: String, List(Int))
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 170),
        " !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant("Bar", " Simple variant", [], []),
          ast.Variant(
            "Baz",
            " Variant with field",
            [ast.UnlabelledField(ast.NamedType("String", option.None, []))],
            [],
          ),
          ast.Variant(
            "Qux",
            " Complex variant",
            [
              ast.LabelledField(
                ast.NamedType("String", option.None, []),
                "name",
              ),
              ast.UnlabelledField(
                ast.NamedType("List", option.None, [
                  ast.NamedType("Int", option.None, []),
                ]),
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_variant_with_function_taking_tuple_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(fn(#(Int, String)) -> Bool)
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 75),
        " !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant(
            "Foo",
            "",
            [
              ast.UnlabelledField(ast.FunctionType(
                [
                  ast.TupleType([
                    ast.NamedType("Int", option.None, []),
                    ast.NamedType("String", option.None, []),
                  ]),
                ],
                ast.NamedType("Bool", option.None, []),
              )),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_variant_with_tuple_containing_function_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(#(Int, fn() -> String))
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 71),
        " !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant(
            "Foo",
            "",
            [
              ast.UnlabelledField(
                ast.TupleType([
                  ast.NamedType("Int", option.None, []),
                  ast.FunctionType([], ast.NamedType("String", option.None, [])),
                ]),
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_variant_with_complex_parameterized_types_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(Result(#(Int, String), List(Error)))
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 84),
        " !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant(
            "Foo",
            "",
            [
              ast.UnlabelledField(
                ast.NamedType("Result", option.None, [
                  ast.TupleType([
                    ast.NamedType("Int", option.None, []),
                    ast.NamedType("String", option.None, []),
                  ]),
                  ast.NamedType("List", option.None, [
                    ast.NamedType("Error", option.None, []),
                  ]),
                ]),
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_multiple_deriveds_test() {
  let custom_types =
    "
  /// First type
  /// !derived(module_a)
  type Foo {
    Foo(String)
  }

  /// Second type
  /// !derived(module_b)
  type Bar {
    Bar(Int)
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 74),
        " First type\n !derived(module_a)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant(
            "Foo",
            "",
            [ast.UnlabelledField(ast.NamedType("String", option.None, []))],
            [],
          ),
        ]),
        ["module_a"],
      ),
      ast.DerivedType(
        #(79, 148),
        " Second type\n !derived(module_b)",
        [],
        ast.Private,
        False,
        ast.Type("Bar", [], [
          ast.Variant(
            "Bar",
            "",
            [ast.UnlabelledField(ast.NamedType("Int", option.None, []))],
            [],
          ),
        ]),
        ["module_b"],
      ),
    ])
}

pub fn parse_docstring_with_multiple_derived_annotations_test() {
  let custom_types =
    "
  /// This is a type with multiple annotations
  /// !derived(first_module)
  /// More documentation here
  /// !derived(second_module)
  type Foo {
    Foo
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 160),
        " This is a type with multiple annotations\n !derived(first_module)\n More documentation here\n !derived(second_module)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [ast.Variant("Foo", "", [], [])]),
        ["first_module", "second_module"],
      ),
    ])
}

pub fn parse_parameterized_type_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo(a) {
    Bar(a)
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 53),
        " !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", ["a"], [
          ast.Variant(
            "Bar",
            "",
            [ast.UnlabelledField(ast.VariableType("a"))],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_variant_with_deprecated_attribute_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    @deprecated(\"use baz instead\")
    Bar
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 82),
        " !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Foo", [], [
          ast.Variant("Bar", "", [], [ast.Deprecated("use baz instead")]),
        ]),
        ["foobar"],
      ),
    ])
}

pub fn parse_type_with_deprecated_attribute_test() {
  let custom_types =
    "
  /// !derived(foobar)
  @deprecated(\"use NewFoo instead\")
  type Foo {
    Bar
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 83),
        " !derived(foobar)",
        [ast.Deprecated("use NewFoo instead")],
        ast.Private,
        False,
        ast.Type("Foo", [], [ast.Variant("Bar", "", [], [])]),
        ["foobar"],
      ),
    ])
}

pub fn parse_type_with_multiple_attributes_test() {
  let custom_types =
    "
  /// !derived(foobar)
  @internal
  @deprecated(\"use NewFoo instead\")
  @target(erlang)
  type Foo {
    Bar
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 113),
        " !derived(foobar)",
        [
          ast.Internal,
          ast.Deprecated("use NewFoo instead"),
          ast.Target(ast.Erlang),
        ],
        ast.Private,
        False,
        ast.Type("Foo", [], [ast.Variant("Bar", "", [], [])]),
        ["foobar"],
      ),
    ])
}

pub fn parse_public_type_test() {
  let custom_types =
    "
  /// !derived(foobar)
  pub type Foo {
    Bar
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 51),
        " !derived(foobar)",
        [],
        ast.Public,
        False,
        ast.Type("Foo", [], [ast.Variant("Bar", "", [], [])]),
        ["foobar"],
      ),
    ])
}

pub fn parse_public_opaque_type_test() {
  let custom_types =
    "
  /// !derived(foobar)
  pub opaque type Foo {
    Bar
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 58),
        " !derived(foobar)",
        [],
        ast.Public,
        True,
        ast.Type("Foo", [], [ast.Variant("Bar", "", [], [])]),
        ["foobar"],
      ),
    ])
}

pub fn parse_attributed_public_type_test() {
  let custom_types =
    "
  /// !derived(foobar)
  @deprecated(\"use NewFoo instead\")
  pub type Foo {
    Bar
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 87),
        " !derived(foobar)",
        [ast.Deprecated("use NewFoo instead")],
        ast.Public,
        False,
        ast.Type("Foo", [], [ast.Variant("Bar", "", [], [])]),
        ["foobar"],
      ),
    ])
}

pub fn parse_attributed_public_opaque_type_test() {
  let custom_types =
    "
  /// !derived(foobar)
  @internal
  pub opaque type Foo {
    Bar
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 70),
        " !derived(foobar)",
        [ast.Internal],
        ast.Public,
        True,
        ast.Type("Foo", [], [ast.Variant("Bar", "", [], [])]),
        ["foobar"],
      ),
    ])
}

pub fn parse_multiple_type_parameters_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Result(a, b) {
    Ok(a)
    Error(b)
  }
  "
    |> ast.parse

  assert custom_types
    == Ok([
      ast.DerivedType(
        #(3, 71),
        " !derived(foobar)",
        [],
        ast.Private,
        False,
        ast.Type("Result", ["a", "b"], [
          ast.Variant(
            "Ok",
            "",
            [ast.UnlabelledField(ast.VariableType("a"))],
            [],
          ),
          ast.Variant(
            "Error",
            "",
            [ast.UnlabelledField(ast.VariableType("b"))],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ])
}
