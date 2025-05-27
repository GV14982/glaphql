/// This module provides validation functions for GraphQL output field types.
/// It ensures that field types are valid according to the GraphQL specification.

import errors
import gleam/dict
import gleam/list
import gleam/result
import internal/executable/types

/// Validates a collection of output field definitions
///
/// Ensures that all field types are defined in the schema and are appropriate
/// for use as output types (not input types).
///
/// ## Arguments
///
/// - `fields`: Dictionary of field definitions to validate
/// - `type_map`: Dictionary of all type definitions in the schema
///
/// ## Returns
///
/// - `Ok(Nil)`: If all field types are valid
/// - `Error(errors.SchemaError)`: If any validation error is found
///
pub fn validate_field_definitions(
  fields: dict.Dict(String, types.ExecutableFieldDef),
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaError) {
  let field_values =
    fields
    |> dict.values
  let field_validation_result =
    field_values
    |> list.fold_until(Ok(Nil), fn(acc, field) {
      case validate_field_type(field.named_type, type_map) {
        Error(err) -> list.Stop(Error(err))
        Ok(_) -> list.Continue(acc)
      }
    })
  use _ <- result.try(field_validation_result)
  Ok(Nil)
}

/// Validates a single field type
///
/// Recursively validates field types, including list types,
/// ensuring they are defined in the schema and are valid output types.
///
/// ## Arguments
///
/// - `field_type`: The field type to validate
/// - `type_map`: Dictionary of all type definitions in the schema
///
/// ## Returns
///
/// - `Ok(Nil)`: If the field type is valid
/// - `Error(errors.SchemaError)`: If the field type is undefined or invalid
///
pub fn validate_field_type(
  field_type: types.ExecutableType,
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaError) {
  case field_type {
    types.ListType(list_type) ->
      validate_field_type(list_type.executable_type, type_map)
    types.NamedType(named_type) -> {
      case type_map |> dict.get(named_type.name) {
        Error(_) ->
          Error(
            errors.InvalidOutputField(errors.UndefinedFieldType(named_type.name)),
          )
        Ok(types.InputTypeDef(_)) ->
          Error(
            errors.InvalidOutputField(errors.InvalidFieldType(named_type.name)),
          )
        Ok(_) -> Ok(Nil)
      }
    }
  }
}
