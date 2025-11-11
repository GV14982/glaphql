import errors
import gleam/dict
import gleam/list
import gleam/result
import internal/executable/types

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
        Ok(types.ScalarTypeDef(_))
        | Ok(types.InputTypeDef(_))
        | Ok(types.EnumTypeDef(_)) -> Ok(Nil)
        Ok(_) ->
          Error(
            errors.InvalidInputField(errors.InvalidFieldType(named_type.name)),
          )
      }
    }
  }
}
