/// This module provides validation functions for GraphQL root operation types.
/// It ensures that the schema's root operations are valid according to the GraphQL specification.
import errors
import gleam/dict
import gleam/option
import gleam/result
import internal/executable/types

/// Validates the schema's root operation types
///
/// Per the GraphQL spec:
/// 1. The query root operation type must be provided and must be an Object type
/// 2. The mutation root operation type is optional; if provided, it must be an Object type
/// 3. The subscription root operation type is optional; if provided, it must be an Object type
///
/// ## Arguments
///
/// - `schema`: The executable schema to validate
///
/// ## Returns
///
/// - `Ok(Nil)`: If all root operation types are valid
/// - `Error(errors.SchemaError)`: If any root operation type is invalid
///
pub fn validate_root_operations(
  schema: types.ExecutableSchema,
) -> Result(Nil, errors.SchemaError) {
  use _ <- result.try(case schema.type_map |> dict.get(schema.query.name) {
    Ok(types.ObjectTypeDef(_)) -> Ok(Nil)
    _ -> Error(errors.MissingQueryType)
  })
  use _ <- result.try(case schema.mutation {
    option.None -> Ok(Nil)
    option.Some(mutation) ->
      case schema.type_map |> dict.get(mutation.name) {
        Ok(types.ObjectTypeDef(_)) -> Ok(Nil)
        Ok(_) -> Error(errors.InvalidRootOperationType)
        Error(_) -> Error(errors.MissingType(mutation.name))
      }
  })
  case schema.subscription {
    option.None -> Ok(Nil)
    option.Some(subscription) ->
      case schema.type_map |> dict.get(subscription.name) {
        Ok(types.ObjectTypeDef(_)) -> Ok(Nil)
        Ok(_) -> Error(errors.InvalidRootOperationType)
        Error(_) -> Error(errors.MissingType(subscription.name))
      }
  }
}
