import errors
import gleam/dict
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
