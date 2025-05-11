import errors
import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import internal/schema/types

pub fn validate_root_operations(
  schema: types.ExecutableSchema,
) -> Result(Nil, errors.SchemaValidationError) {
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

pub fn check_unique_names(
  type_maps: List(dict.Dict(String, types.ExecutableTypeDef)),
) -> Result(Nil, errors.SchemaValidationError) {
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
      check_unique_names(type_maps)
    }
    [] -> Ok(Nil)
  }
}
