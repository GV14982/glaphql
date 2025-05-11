import errors
import gleam/dict
import gleam/list
import internal/schema/types
import internal/validate/util

@internal
pub fn validate_value_to_def(
  value: types.ExecutableConstValue,
  def: types.ExecutableInputValueDef,
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaValidationError) {
  case value {
    types.ExecutableConstScalar(scalar) ->
      validate_scalar_type(scalar, def, type_map)
    types.ExecutableConstObject(val) ->
      case def.named_type {
        types.NamedType(types.ExecutableNamedType(name:, nullable: _)) -> {
          case type_map |> dict.get(name) {
            Ok(types.InputTypeDef(types.ExecutableInputTypeDef(
              description: _,
              directives: _,
              name: _,
              fields:,
            ))) -> validate_input_field_values(val, fields, type_map)
            Ok(_) -> Error(todo as "Make error for invalid input type")
            _ -> Error(errors.MissingType(name))
          }
        }
        _ -> Error(todo as "should never get here")
      }
    types.ExecutableConstList(vals) ->
      vals
      |> list.fold_until(Ok(Nil), fn(acc, val) {
        case validate_value_to_def(val, def, type_map) {
          Ok(_) -> list.Continue(acc)
          Error(err) -> list.Stop(Error(err))
        }
      })
  }
}

@internal
pub fn validate_scalar_type(
  scalar: types.ExecutableConstScalar,
  arg: types.ExecutableInputValueDef,
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaValidationError) {
  case scalar {
    types.ExecutableBoolVal(_)
    | types.ExecutableFloatVal(_)
    | types.ExecutableIntVal(_)
    | types.ExecutableStringVal(_) ->
      case arg.named_type {
        types.NamedType(types.ExecutableNamedType(name:, nullable: _)) ->
          case type_map |> dict.get(name) {
            Ok(types.ScalarTypeDef(_)) -> Ok(Nil)
            _ -> Error(errors.MissingType(name))
          }
        _ -> Error(todo as "should never get here")
      }
    types.ExecutableEnumVal(val) -> {
      case arg.named_type {
        types.NamedType(types.ExecutableNamedType(name:, nullable: _)) ->
          case type_map |> dict.get(name) {
            Ok(types.EnumTypeDef(types.ExecutableEnumTypeDef(
              description: _,
              directives: _,
              members:,
              name: _,
            ))) -> {
              case members |> list.any(fn(member) { member.name == val }) {
                True -> Ok(Nil)
                False ->
                  Error(
                    errors.InvalidConstValueUsage(errors.InvalidEnumValue(val)),
                  )
              }
            }
            _ -> Error(errors.MissingType(name))
          }
        _ -> Error(todo as "should never get here")
      }
    }
    types.ExecutableNullVal -> {
      case util.is_nullable(arg.named_type) {
        True -> Ok(Nil)
        False ->
          Error(errors.InvalidConstValueUsage(errors.NullValueForNonNullType))
      }
    }
  }
}

@internal
pub fn validate_input_field_values(
  values: dict.Dict(String, types.ExecutableConstValue),
  fields: dict.Dict(String, types.ExecutableInputValueDef),
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaValidationError) {
  fields
  |> dict.to_list
  |> list.fold_until(Ok(Nil), fn(acc, val) {
    let #(field_name, field) = val
    case values |> dict.get(field_name), util.is_nullable(field.named_type) {
      Ok(value), _ ->
        list.Continue(validate_value_to_def(value, field, type_map))
      _, True -> list.Continue(acc)
      _, _ -> list.Stop(Error(todo as "create invalid value error"))
    }
  })
}
