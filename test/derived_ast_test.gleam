import derived_ast
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
    |> derived_ast.parse

  assert custom_types == []
}

pub fn ignore_unteathered_docstring_test() {
  let custom_types =
    "
    /// this is a docstring
    /// of many lines
    /// but it doesn't contain the codgen_type magic string
    "
    |> derived_ast.parse

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
    |> derived_ast.parse

  assert custom_types == []
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
    |> derived_ast.parse

  assert custom_types == []
}

pub fn parse_empty_private_derived_test() {
  let custom_types =
    "
    /// A real derived type!
    /// !derived(foobar)
    type Foo {}
    "
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(5, 69),
        " A real derived type!\n !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], []),
        ["foobar"],
      ),
    ]
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
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(5, 84),
        " A real derived type!\n !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [derived_ast.Variant("Foo", "", [], [])]),
        ["foobar"],
      ),
    ]
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
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(5, 116),
        " A real derived type!\n !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant("Foo", " A Foo does foo things", [], []),
        ]),
        ["foobar"],
      ),
    ]
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
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(5, 158),
        " A real derived type!\n !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant("Foo", " A Foo does foo things", [], []),
          derived_ast.Variant("Bar", " A Bar does bar things", [], []),
        ]),
        ["foobar"],
      ),
    ]
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
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(5, 106),
        " !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant(
            "Foo",
            " A Foo does foo things",
            [
              derived_ast.UnlabelledField(
                derived_ast.NamedType("String", option.None, []),
              ),
              derived_ast.UnlabelledField(derived_ast.NamedType("Int", option.None, [])),
              derived_ast.UnlabelledField(
                derived_ast.NamedType("Bool", option.None, []),
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ]
}

pub fn parse_variant_with_multiple_labelled_field_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(bar: String, baz: Int)
  }
  "
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 70),
        " !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant(
            "Foo",
            "",
            [
              derived_ast.LabelledField(
                derived_ast.NamedType("String", option.None, []),
                "bar",
              ),
              derived_ast.LabelledField(
                derived_ast.NamedType("Int", option.None, []),
                "baz",
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ]
}

pub fn parse_variant_with_nested_tuple_field_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(#(Int, #(String, Bool)))
  }
  "
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 72),
        " !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant(
            "Foo",
            "",
            [
              derived_ast.UnlabelledField(
                derived_ast.TupleType([
                  derived_ast.NamedType("Int", option.None, []),
                  derived_ast.TupleType([
                    derived_ast.NamedType("String", option.None, []),
                    derived_ast.NamedType("Bool", option.None, []),
                  ]),
                ]),
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ]
}

pub fn parse_variant_with_parameterized_field_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(List(Int))
  }
  "
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 58),
        " !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant(
            "Foo",
            "",
            [
              derived_ast.UnlabelledField(
                derived_ast.NamedType("List", option.None, [
                  derived_ast.NamedType("Int", option.None, []),
                ]),
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ]
}

pub fn parse_variant_with_zero_parameter_function_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(fn() -> Int)
  }
  "
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 60),
        " !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant(
            "Foo",
            "",
            [
              derived_ast.UnlabelledField(derived_ast.FunctionType(
                [],
                derived_ast.NamedType("Int", option.None, []),
              )),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ]
}

pub fn parse_variant_with_mixed_fields_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(String, bar: Int, Bool)
  }
  "
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 71),
        " !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant(
            "Foo",
            "",
            [
              derived_ast.UnlabelledField(
                derived_ast.NamedType("String", option.None, []),
              ),
              derived_ast.LabelledField(
                derived_ast.NamedType("Int", option.None, []),
                "bar",
              ),
              derived_ast.UnlabelledField(
                derived_ast.NamedType("Bool", option.None, []),
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ]
}

pub fn parse_variant_with_module_qualified_parameterized_field_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(option.Option(String))
  }
  "
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 70),
        " !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant(
            "Foo",
            "",
            [
              derived_ast.UnlabelledField(
                derived_ast.NamedType("Option", option.Some("option"), [
                  derived_ast.NamedType("String", option.None, []),
                ]),
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ]
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
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 170),
        " !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant("Bar", " Simple variant", [], []),
          derived_ast.Variant(
            "Baz",
            " Variant with field",
            [
              derived_ast.UnlabelledField(
                derived_ast.NamedType("String", option.None, []),
              ),
            ],
            [],
          ),
          derived_ast.Variant(
            "Qux",
            " Complex variant",
            [
              derived_ast.LabelledField(
                derived_ast.NamedType("String", option.None, []),
                "name",
              ),
              derived_ast.UnlabelledField(
                derived_ast.NamedType("List", option.None, [
                  derived_ast.NamedType("Int", option.None, []),
                ]),
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ]
}

pub fn parse_variant_with_function_taking_tuple_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(fn(#(Int, String)) -> Bool)
  }
  "
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 75),
        " !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant(
            "Foo",
            "",
            [
              derived_ast.UnlabelledField(derived_ast.FunctionType(
                [
                  derived_ast.TupleType([
                    derived_ast.NamedType("Int", option.None, []),
                    derived_ast.NamedType("String", option.None, []),
                  ]),
                ],
                derived_ast.NamedType("Bool", option.None, []),
              )),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ]
}

pub fn parse_variant_with_tuple_containing_function_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(#(Int, fn() -> String))
  }
  "
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 71),
        " !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant(
            "Foo",
            "",
            [
              derived_ast.UnlabelledField(
                derived_ast.TupleType([
                  derived_ast.NamedType("Int", option.None, []),
                  derived_ast.FunctionType(
                    [],
                    derived_ast.NamedType("String", option.None, []),
                  ),
                ]),
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ]
}

pub fn parse_variant_with_complex_parameterized_types_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo {
    Foo(Result(#(Int, String), List(Error)))
  }
  "
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 84),
        " !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant(
            "Foo",
            "",
            [
              derived_ast.UnlabelledField(
                derived_ast.NamedType("Result", option.None, [
                  derived_ast.TupleType([
                    derived_ast.NamedType("Int", option.None, []),
                    derived_ast.NamedType("String", option.None, []),
                  ]),
                  derived_ast.NamedType("List", option.None, [
                    derived_ast.NamedType("Error", option.None, []),
                  ]),
                ]),
              ),
            ],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ]
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
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 74),
        " First type\n !derived(module_a)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant(
            "Foo",
            "",
            [
              derived_ast.UnlabelledField(
                derived_ast.NamedType("String", option.None, []),
              ),
            ],
            [],
          ),
        ]),
        ["module_a"],
      ),
      derived_ast.DerivedType(
        #(79, 148),
        " Second type\n !derived(module_b)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Bar", [], [
          derived_ast.Variant(
            "Bar",
            "",
            [derived_ast.UnlabelledField(derived_ast.NamedType("Int", option.None, []))],
            [],
          ),
        ]),
        ["module_b"],
      ),
    ]
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
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 160),
        " This is a type with multiple annotations\n !derived(first_module)\n More documentation here\n !derived(second_module)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [derived_ast.Variant("Foo", "", [], [])]),
        ["first_module", "second_module"],
      ),
    ]
}

pub fn parse_parameterized_type_test() {
  let custom_types =
    "
  /// !derived(foobar)
  type Foo(a) {
    Bar(a)
  }
  "
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 53),
        " !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", ["a"], [
          derived_ast.Variant(
            "Bar",
            "",
            [derived_ast.UnlabelledField(derived_ast.VariableType("a"))],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ]
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
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 82),
        " !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [
          derived_ast.Variant("Bar", "", [], [derived_ast.Deprecated("use baz instead")]),
        ]),
        ["foobar"],
      ),
    ]
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
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 83),
        " !derived(foobar)",
        [derived_ast.Deprecated("use NewFoo instead")],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [derived_ast.Variant("Bar", "", [], [])]),
        ["foobar"],
      ),
    ]
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
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 113),
        " !derived(foobar)",
        [
          derived_ast.Internal,
          derived_ast.Deprecated("use NewFoo instead"),
          derived_ast.Target(derived_ast.Erlang),
        ],
        derived_ast.Private,
        False,
        derived_ast.Type("Foo", [], [derived_ast.Variant("Bar", "", [], [])]),
        ["foobar"],
      ),
    ]
}

pub fn parse_public_type_test() {
  let custom_types =
    "
  /// !derived(foobar)
  pub type Foo {
    Bar
  }
  "
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 51),
        " !derived(foobar)",
        [],
        derived_ast.Public,
        False,
        derived_ast.Type("Foo", [], [derived_ast.Variant("Bar", "", [], [])]),
        ["foobar"],
      ),
    ]
}

pub fn parse_public_opaque_type_test() {
  let custom_types =
    "
  /// !derived(foobar)
  pub opaque type Foo {
    Bar
  }
  "
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 58),
        " !derived(foobar)",
        [],
        derived_ast.Public,
        True,
        derived_ast.Type("Foo", [], [derived_ast.Variant("Bar", "", [], [])]),
        ["foobar"],
      ),
    ]
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
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 87),
        " !derived(foobar)",
        [derived_ast.Deprecated("use NewFoo instead")],
        derived_ast.Public,
        False,
        derived_ast.Type("Foo", [], [derived_ast.Variant("Bar", "", [], [])]),
        ["foobar"],
      ),
    ]
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
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 70),
        " !derived(foobar)",
        [derived_ast.Internal],
        derived_ast.Public,
        True,
        derived_ast.Type("Foo", [], [derived_ast.Variant("Bar", "", [], [])]),
        ["foobar"],
      ),
    ]
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
    |> derived_ast.parse

  assert custom_types
    == [
      derived_ast.DerivedType(
        #(3, 71),
        " !derived(foobar)",
        [],
        derived_ast.Private,
        False,
        derived_ast.Type("Result", ["a", "b"], [
          derived_ast.Variant(
            "Ok",
            "",
            [derived_ast.UnlabelledField(derived_ast.VariableType("a"))],
            [],
          ),
          derived_ast.Variant(
            "Error",
            "",
            [derived_ast.UnlabelledField(derived_ast.VariableType("b"))],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ]
}
