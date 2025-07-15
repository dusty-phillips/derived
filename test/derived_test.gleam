import derived
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
    |> derived.parse

  assert custom_types == []
}

pub fn ignore_unteathered_docstring_test() {
  let custom_types =
    "
    /// this is a docstring
    /// of many lines
    /// but it doesn't contain the codgen_type magic string
    "
    |> derived.parse

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
    |> derived.parse

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
    |> derived.parse

  assert custom_types == []
}

pub fn parse_empty_private_derived_test() {
  let custom_types =
    "
    /// A real derived type!
    /// !derived(foobar)
    type Foo {}
    "
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(5, 69),
        " A real derived type!\n !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], []),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(5, 84),
        " A real derived type!\n !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [derived.Variant("Foo", "", [], [])]),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(5, 116),
        " A real derived type!\n !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant("Foo", " A Foo does foo things", [], []),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(5, 158),
        " A real derived type!\n !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant("Foo", " A Foo does foo things", [], []),
          derived.Variant("Bar", " A Bar does bar things", [], []),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(5, 106),
        " !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant(
            "Foo",
            " A Foo does foo things",
            [
              derived.UnlabelledField(
                derived.NamedType("String", option.None, []),
              ),
              derived.UnlabelledField(derived.NamedType("Int", option.None, [])),
              derived.UnlabelledField(
                derived.NamedType("Bool", option.None, []),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 70),
        " !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant(
            "Foo",
            "",
            [
              derived.LabelledField(
                derived.NamedType("String", option.None, []),
                "bar",
              ),
              derived.LabelledField(
                derived.NamedType("Int", option.None, []),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 72),
        " !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant(
            "Foo",
            "",
            [
              derived.UnlabelledField(
                derived.TupleType([
                  derived.NamedType("Int", option.None, []),
                  derived.TupleType([
                    derived.NamedType("String", option.None, []),
                    derived.NamedType("Bool", option.None, []),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 58),
        " !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant(
            "Foo",
            "",
            [
              derived.UnlabelledField(
                derived.NamedType("List", option.None, [
                  derived.NamedType("Int", option.None, []),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 60),
        " !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant(
            "Foo",
            "",
            [
              derived.UnlabelledField(derived.FunctionType(
                [],
                derived.NamedType("Int", option.None, []),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 71),
        " !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant(
            "Foo",
            "",
            [
              derived.UnlabelledField(
                derived.NamedType("String", option.None, []),
              ),
              derived.LabelledField(
                derived.NamedType("Int", option.None, []),
                "bar",
              ),
              derived.UnlabelledField(
                derived.NamedType("Bool", option.None, []),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 70),
        " !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant(
            "Foo",
            "",
            [
              derived.UnlabelledField(
                derived.NamedType("Option", option.Some("option"), [
                  derived.NamedType("String", option.None, []),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 170),
        " !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant("Bar", " Simple variant", [], []),
          derived.Variant(
            "Baz",
            " Variant with field",
            [
              derived.UnlabelledField(
                derived.NamedType("String", option.None, []),
              ),
            ],
            [],
          ),
          derived.Variant(
            "Qux",
            " Complex variant",
            [
              derived.LabelledField(
                derived.NamedType("String", option.None, []),
                "name",
              ),
              derived.UnlabelledField(
                derived.NamedType("List", option.None, [
                  derived.NamedType("Int", option.None, []),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 75),
        " !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant(
            "Foo",
            "",
            [
              derived.UnlabelledField(derived.FunctionType(
                [
                  derived.TupleType([
                    derived.NamedType("Int", option.None, []),
                    derived.NamedType("String", option.None, []),
                  ]),
                ],
                derived.NamedType("Bool", option.None, []),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 71),
        " !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant(
            "Foo",
            "",
            [
              derived.UnlabelledField(
                derived.TupleType([
                  derived.NamedType("Int", option.None, []),
                  derived.FunctionType(
                    [],
                    derived.NamedType("String", option.None, []),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 84),
        " !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant(
            "Foo",
            "",
            [
              derived.UnlabelledField(
                derived.NamedType("Result", option.None, [
                  derived.TupleType([
                    derived.NamedType("Int", option.None, []),
                    derived.NamedType("String", option.None, []),
                  ]),
                  derived.NamedType("List", option.None, [
                    derived.NamedType("Error", option.None, []),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 74),
        " First type\n !derived(module_a)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant(
            "Foo",
            "",
            [
              derived.UnlabelledField(
                derived.NamedType("String", option.None, []),
              ),
            ],
            [],
          ),
        ]),
        ["module_a"],
      ),
      derived.DerivedType(
        #(79, 148),
        " Second type\n !derived(module_b)",
        [],
        derived.Private,
        False,
        derived.Type("Bar", [], [
          derived.Variant(
            "Bar",
            "",
            [derived.UnlabelledField(derived.NamedType("Int", option.None, []))],
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 160),
        " This is a type with multiple annotations\n !derived(first_module)\n More documentation here\n !derived(second_module)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [derived.Variant("Foo", "", [], [])]),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 53),
        " !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", ["a"], [
          derived.Variant(
            "Bar",
            "",
            [derived.UnlabelledField(derived.VariableType("a"))],
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 82),
        " !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Foo", [], [
          derived.Variant("Bar", "", [], [derived.Deprecated("use baz instead")]),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 83),
        " !derived(foobar)",
        [derived.Deprecated("use NewFoo instead")],
        derived.Private,
        False,
        derived.Type("Foo", [], [derived.Variant("Bar", "", [], [])]),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 113),
        " !derived(foobar)",
        [
          derived.Internal,
          derived.Deprecated("use NewFoo instead"),
          derived.Target(derived.Erlang),
        ],
        derived.Private,
        False,
        derived.Type("Foo", [], [derived.Variant("Bar", "", [], [])]),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 51),
        " !derived(foobar)",
        [],
        derived.Public,
        False,
        derived.Type("Foo", [], [derived.Variant("Bar", "", [], [])]),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 58),
        " !derived(foobar)",
        [],
        derived.Public,
        True,
        derived.Type("Foo", [], [derived.Variant("Bar", "", [], [])]),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 87),
        " !derived(foobar)",
        [derived.Deprecated("use NewFoo instead")],
        derived.Public,
        False,
        derived.Type("Foo", [], [derived.Variant("Bar", "", [], [])]),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 70),
        " !derived(foobar)",
        [derived.Internal],
        derived.Public,
        True,
        derived.Type("Foo", [], [derived.Variant("Bar", "", [], [])]),
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
    |> derived.parse

  assert custom_types
    == [
      derived.DerivedType(
        #(3, 71),
        " !derived(foobar)",
        [],
        derived.Private,
        False,
        derived.Type("Result", ["a", "b"], [
          derived.Variant(
            "Ok",
            "",
            [derived.UnlabelledField(derived.VariableType("a"))],
            [],
          ),
          derived.Variant(
            "Error",
            "",
            [derived.UnlabelledField(derived.VariableType("b"))],
            [],
          ),
        ]),
        ["foobar"],
      ),
    ]
}
