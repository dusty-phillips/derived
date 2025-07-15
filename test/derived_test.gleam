import derived
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn generate_single_type_no_markers_test() {
  let source =
    "
/// A simple type
/// !derived(test_module)
type Foo {
  Bar
}
"

  let result =
    derived.generate(source, fn(derived_type) {
      case derived_type.derived_names {
        ["test_module"] ->
          Ok("generated code for " <> derived_type.parsed_type.name)
        _ -> Error(Nil)
      }
    })

  assert result == "
/// A simple type
/// !derived(test_module)
type Foo {
  Bar
}

// ---- BEGIN DERIVED test_module DO NOT MODIFY ---- //
generated code for Foo
// ---- END DERIVED test_module //
"
}

pub fn generate_single_type_replace_markers_test() {
  let source =
    "
/// A simple type
/// !derived(test_module)
type Foo {
  Bar
}

// ---- BEGIN DERIVED test_module DO NOT MODIFY ---- //
old generated code
// ---- END DERIVED test_module //
"

  let result =
    derived.generate(source, fn(derived_type) {
      case derived_type.derived_names {
        ["test_module"] ->
          Ok("new generated code for " <> derived_type.parsed_type.name)
        _ -> Error(Nil)
      }
    })

  assert result == "
/// A simple type
/// !derived(test_module)
type Foo {
  Bar
}

// ---- BEGIN DERIVED test_module DO NOT MODIFY ---- //
new generated code for Foo
// ---- END DERIVED test_module //
"
}

pub fn generate_multiple_types_test() {
  let source =
    "
/// First type
/// !derived(module_a)
type Foo {
  Bar
}

/// Second type
/// !derived(module_b)
type Baz {
  Qux
}
"

  let result =
    derived.generate(source, fn(derived_type) {
      case derived_type.derived_names {
        ["module_a"] -> Ok("generated A for " <> derived_type.parsed_type.name)
        ["module_b"] -> Ok("generated B for " <> derived_type.parsed_type.name)
        _ -> Error(Nil)
      }
    })

  assert result == "
/// First type
/// !derived(module_a)
type Foo {
  Bar
}

// ---- BEGIN DERIVED module_a DO NOT MODIFY ---- //
generated A for Foo
// ---- END DERIVED module_a //

/// Second type
/// !derived(module_b)
type Baz {
  Qux
}

// ---- BEGIN DERIVED module_b DO NOT MODIFY ---- //
generated B for Baz
// ---- END DERIVED module_b //
"
}

pub fn generate_single_type_multiple_derivations_test() {
  let source =
    "
/// A type with multiple derivations
/// !derived(first_module)
/// More documentation
/// !derived(second_module)
type Foo {
  Bar
}
"

  let result =
    derived.generate(source, fn(derived_type) {
      case derived_type.derived_names {
        ["first_module", "second_module"] ->
          Ok("generated for " <> derived_type.parsed_type.name)
        _ -> Error(Nil)
      }
    })

  assert result == "
/// A type with multiple derivations
/// !derived(first_module)
/// More documentation
/// !derived(second_module)
type Foo {
  Bar
}

// ---- BEGIN DERIVED first_module DO NOT MODIFY ---- //
generated for Foo
// ---- END DERIVED first_module //

// ---- BEGIN DERIVED second_module DO NOT MODIFY ---- //
generated for Foo
// ---- END DERIVED second_module //
"
}

pub fn generate_no_derived_types_test() {
  let source =
    "
/// A regular type without derivation
type Foo {
  Bar
}

/// Another regular type
type Baz {
  Qux
}
"

  let result =
    derived.generate(source, fn(_derived_type) {
      Ok("this should never be called")
    })

  assert result == source
}

pub fn generate_callback_error_test() {
  let source =
    "
/// A derived type
/// !derived(test_module)
type Foo {
  Bar
}

/// Another derived type
/// !derived(other_module)
type Baz {
  Qux
}
"

  let result =
    derived.generate(source, fn(derived_type) {
      case derived_type.derived_names {
        ["test_module"] -> Ok("generated for " <> derived_type.parsed_type.name)
        ["other_module"] -> Error(Nil)
        _ -> Error(Nil)
      }
    })

  assert result == "
/// A derived type
/// !derived(test_module)
type Foo {
  Bar
}

// ---- BEGIN DERIVED test_module DO NOT MODIFY ---- //
generated for Foo
// ---- END DERIVED test_module //

/// Another derived type
/// !derived(other_module)
type Baz {
  Qux
}
"
}
