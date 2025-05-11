/// This module provides validation functions for GraphQL input field types.
/// It ensures that input field types are valid according to the GraphQL specification.

import errors
import gleam/dict
import gleam/list
import gleam/result
import internal/schema/types

/// Validates a collection of input field definitions
///
/// Ensures that all input field types are defined in the schema and are appropriate
/// for use as input types (input objects or scalars).
///
/// ## Arguments
///
/// - `input_fields`: Dictionary of input field definitions to validate
/// - `type_map`: Dictionary of all type definitions in the schema
///
/// ## Returns
///
/// - `Ok(Nil)`: If all input field types are valid
/// - `Error(errors.SchemaError)`: If any validation error is found
///
pub fn validate_input_field_definitions(
  input_fields: dict.Dict(String, types.ExecutableInputValueDef),
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaError) {
  let input_field_values =
    input_fields
    |> dict.values
  let input_field_validation_result =
    input_field_values
    |> list.fold_until(Ok(Nil), fn(acc, input_field) {
      case validate_input_field_type(input_field.named_type, type_map) {
        Error(err) -> list.Stop(Error(err))
        Ok(_) -> list.Continue(acc)
      }
    })
  use _ <- result.try(input_field_validation_result)
  Ok(Nil)
}

/// Validates a single input field type
///
/// Recursively validates input field types, including list types,
/// ensuring they are defined in the schema and are valid input types.
/// According to the GraphQL spec, valid input types are:
/// - Scalar types
/// - Input object types
/// - List types containing valid input types
///
/// ## Arguments
///
/// - `input_field_type`: The input field type to validate
/// - `type_map`: Dictionary of all type definitions in the schema
///
/// ## Returns
///
/// - `Ok(Nil)`: If the input field type is valid
/// - `Error(errors.SchemaError)`: If the input field type is undefined or invalid
///
pub fn validate_input_field_type(
  input_field_type: types.ExecutableType,
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaError) {
  case input_field_type {
    types.ListType(list_type) ->
      validate_input_field_type(list_type.executable_type, type_map)
    types.NamedType(named_type) -> {
      case type_map |> dict.get(named_type.name) {
        Error(_) ->
          Error(
            errors.InvalidInputField(errors.UndefinedFieldType(named_type.name)),
          )
        Ok(types.InputTypeDef(_)) -> Ok(Nil)
        Ok(types.ScalarTypeDef(_)) -> Ok(Nil)
        Ok(_) ->
          Error(
            errors.InvalidInputField(errors.InvalidFieldType(named_type.name)),
          )
      }
    }
  }
}
