/// This module provides name validation functions for GraphQL schemas.
/// It ensures that type names are unique across different type categories.
import errors
import gleam/dict
import gleam/list
import gleam/result
import internal/executable/types

/// Validates that type names are unique across different type categories
///
/// Per the GraphQL spec, all types within a GraphQL schema must have unique names.
/// This function verifies that there are no name collisions across different type
/// categories (objects, enums, scalars, interfaces, unions, inputs).
///
/// ## Arguments
///
/// - `type_maps`: A list of dictionaries representing different type categories
///
/// ## Returns
///
/// - `Ok(Nil)` if all type names are unique across categories
/// - `Error(errors.SchemaError)` if any name collision is found
///
pub fn validate_unique_names(
  type_maps: List(dict.Dict(String, types.ExecutableTypeDef)),
) -> Result(Nil, errors.SchemaError) {
  case type_maps {
    [curr, ..type_maps] -> {
      use _ <- result.try(
        curr
        |> dict.keys
        |> list.fold_until(Ok(Nil), fn(acc, name) {
          let has_conflict =
            type_maps |> list.any(fn(map) { map |> dict.has_key(name) })
          case has_conflict {
            True -> list.Stop(Error(errors.NameCollision(name)))
            False -> list.Continue(acc)
          }
        }),
      )
      validate_unique_names(type_maps)
    }
    [] -> Ok(Nil)
  }
}
