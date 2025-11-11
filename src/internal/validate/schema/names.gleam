import errors
import gleam/dict
import gleam/list
import gleam/result
import internal/executable/types

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
