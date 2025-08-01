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
    derived.generate(source, "test_module", fn(derived_type) {
      Ok("generated code for " <> derived_type.parsed_type.name)
    })

  assert result == "
/// A simple type
/// !derived(test_module)
type Foo {
  Bar
}

// ---- BEGIN DERIVED test_module for Foo DO NOT MODIFY ---- //
generated code for Foo
// ---- END DERIVED test_module for Foo //
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

// ---- BEGIN DERIVED test_module for Foo DO NOT MODIFY ---- //
old generated code
// ---- END DERIVED test_module for Foo //
"

  let result =
    derived.generate(source, "test_module", fn(derived_type) {
      Ok("new generated code for " <> derived_type.parsed_type.name)
    })

  assert result == "
/// A simple type
/// !derived(test_module)
type Foo {
  Bar
}

// ---- BEGIN DERIVED test_module for Foo DO NOT MODIFY ---- //
new generated code for Foo
// ---- END DERIVED test_module for Foo //
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

  let result_a =
    derived.generate(source, "module_a", fn(derived_type) {
      Ok("generated A for " <> derived_type.parsed_type.name)
    })
  
  let result =
    derived.generate(result_a, "module_b", fn(derived_type) {
      Ok("generated B for " <> derived_type.parsed_type.name)
    })

  assert result == "
/// First type
/// !derived(module_a)
type Foo {
  Bar
}

// ---- BEGIN DERIVED module_a for Foo DO NOT MODIFY ---- //
generated A for Foo
// ---- END DERIVED module_a for Foo //

/// Second type
/// !derived(module_b)
type Baz {
  Qux
}

// ---- BEGIN DERIVED module_b for Baz DO NOT MODIFY ---- //
generated B for Baz
// ---- END DERIVED module_b for Baz //
"
}

pub fn generate_multiple_types_same_derived_name_test() {
  let source =
    "
/// First type
/// !derived(shared_module)
type Foo {
  Bar
}

/// Second type
/// !derived(shared_module)
type Baz {
  Qux
}
"

  let result =
    derived.generate(source, "shared_module", fn(derived_type) {
      Ok("generated for " <> derived_type.parsed_type.name)
    })

  assert result == "
/// First type
/// !derived(shared_module)
type Foo {
  Bar
}

// ---- BEGIN DERIVED shared_module for Foo DO NOT MODIFY ---- //
generated for Foo
// ---- END DERIVED shared_module for Foo //

/// Second type
/// !derived(shared_module)
type Baz {
  Qux
}

// ---- BEGIN DERIVED shared_module for Baz DO NOT MODIFY ---- //
generated for Baz
// ---- END DERIVED shared_module for Baz //
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

  let result_first =
    derived.generate(source, "first_module", fn(derived_type) {
      Ok("generated for " <> derived_type.parsed_type.name)
    })
  
  assert result_first == "
/// A type with multiple derivations
/// !derived(first_module)
/// More documentation
/// !derived(second_module)
type Foo {
  Bar
}

// ---- BEGIN DERIVED first_module for Foo DO NOT MODIFY ---- //
generated for Foo
// ---- END DERIVED first_module for Foo //
"
  
  let result =
    derived.generate(result_first, "second_module", fn(derived_type) {
      Ok("generated for " <> derived_type.parsed_type.name)
    })

  assert result == "
/// A type with multiple derivations
/// !derived(first_module)
/// More documentation
/// !derived(second_module)
type Foo {
  Bar
}

// ---- BEGIN DERIVED second_module for Foo DO NOT MODIFY ---- //
generated for Foo
// ---- END DERIVED second_module for Foo //

// ---- BEGIN DERIVED first_module for Foo DO NOT MODIFY ---- //
generated for Foo
// ---- END DERIVED first_module for Foo //
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
    derived.generate(source, "nonexistent_module", fn(_derived_type) {
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
    derived.generate(source, "test_module", fn(derived_type) {
      Ok("generated for " <> derived_type.parsed_type.name)
    })

  assert result == "
/// A derived type
/// !derived(test_module)
type Foo {
  Bar
}

// ---- BEGIN DERIVED test_module for Foo DO NOT MODIFY ---- //
generated for Foo
// ---- END DERIVED test_module for Foo //

/// Another derived type
/// !derived(other_module)
type Baz {
  Qux
}
"
}

pub fn generate_non_matching_derived_name_test() {
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
    derived.generate(source, "non_matching_module", fn(_derived_type) {
      Ok("this should never be called")
    })

  assert result == source
}
