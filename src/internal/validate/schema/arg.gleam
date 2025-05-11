/// This module provides validation functions for GraphQL arguments.
/// It ensures that arguments are valid according to the GraphQL specification.

import errors
import gleam/dict
import gleam/list
import internal/schema/types
import internal/validate/schema/value

/// Validates arguments against their definitions
///
/// Ensures that all provided arguments are defined and have valid values.
///
/// ## Arguments
///
/// - `args`: Dictionary of argument values
/// - `arg_defs`: Dictionary of argument definitions
/// - `type_map`: Dictionary of all type definitions in the schema
///
/// ## Returns
///
/// - `Ok(Nil)`: If all arguments are valid
/// - `Error(errors.SchemaError)`: If any validation error is found
///
pub fn validate_arguments(
  args: dict.Dict(String, types.ExecutableConstValue),
  arg_defs: dict.Dict(String, types.ExecutableInputValueDef),
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaError) {
  args
  |> dict.to_list
  |> list.fold_until(Ok(Nil), fn(_, arg) {
    let #(name, val) = arg
    case arg_defs |> dict.get(name) {
      Ok(def) -> list.Continue(value.validate_value_to_def(val, def, type_map))
      Error(_) ->
        list.Stop(Error(errors.InvalidArgument(errors.UndefinedArgument(name))))
    }
  })
}
