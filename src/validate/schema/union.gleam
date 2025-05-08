import errors
import gleam/dict
import gleam/list
import gleam/result
import schema/types

@internal
pub fn check_union_members(
  union: types.ExecutableUnionTypeDef,
  type_maps: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaValidationError) {
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
