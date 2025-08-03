import derived/ast
import derived/generate

pub fn parse(input: String) -> Result(List(ast.DerivedType), ast.ParseError) {
  ast.parse(input)
}

pub fn generate(
  input: String,
  derived_name: String,
  callback: fn(ast.DerivedType) -> Result(String, a),
) -> Result(String, generate.GenerateError(a)) {
  generate.generate(input, derived_name, callback)
}
