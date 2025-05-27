/// This module provides validation functions for GraphQL union members.
/// It ensures that union members follow the GraphQL specification.
import errors
import gleam/dict
import gleam/list
import gleam/result
import internal/executable/types

/// Validates that all members of a union type are valid object types
///
/// Per the GraphQL spec, union members must:
/// 1. Be defined in the schema
/// 2. Be object types (not scalars, enums, unions, interfaces, or input types)
///
/// ## Arguments
///
/// - `union`: The union type definition to validate
/// - `type_maps`: Dictionary of all type definitions in the schema
///
/// ## Returns
///
/// - `Ok(Nil)` if all union members are valid
/// - `Error(errors.SchemaError)` if any validation error is found
///
pub fn validate_union_members(
  union: types.ExecutableUnionTypeDef,
  type_maps: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaError) {
  union.members
  |> list.fold_until(Ok(Nil), fn(acc, curr) {
    case type_maps |> dict.get(curr) {
      Ok(types.ObjectTypeDef(_)) -> list.Continue(acc)
      Ok(_) ->
        list.Stop(Error(errors.NonObjectMember(name: union.name, member: curr)))
      _ ->
        list.Stop(Error(errors.UndefinedMember(name: union.name, member: curr)))
    }
  })
  |> result.map_error(errors.InvalidUnionMember)
}
