import errors
import gleam/dict
import gleam/list
import gleam/result
import schema/types

@internal
pub fn validate_field_definitions(
  fields: dict.Dict(String, types.ExecutableFieldDef),
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaValidationError) {
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

@internal
pub fn validate_field_type(
  field_type: types.ExecutableType,
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaValidationError) {
  case field_type {
    types.ListType(list_type) ->
      validate_field_type(list_type.executable_type, type_map)
    types.NamedType(named_type) -> {
      case type_map |> dict.get(named_type.name) {
        Error(_) ->
          Error(
            errors.InvalidOutputField(errors.UndefinedOutputFieldType(
              named_type.name,
            )),
          )
        Ok(types.InputTypeDef(types.ExecutableInputTypeDef(
          description: _,
          directives: _,
          fields: _,
          name: _,
        ))) ->
          Error(
            errors.InvalidOutputField(errors.InvalidOutputFieldType(
              named_type.name,
            )),
          )
        Ok(_) -> Ok(Nil)
      }
    }
  }
}
