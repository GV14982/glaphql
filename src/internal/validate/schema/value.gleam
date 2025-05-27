import errors
import gleam/bool
import gleam/dict
import gleam/list
import internal/executable/types
import internal/validate/util

pub fn validate_value_to_def(
  value: types.ExecutableConstValue,
  def: types.ExecutableInputValueDef,
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaError) {
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
            Ok(_) -> Error(errors.InvalidInputType(name))
            _ -> Error(errors.MissingType(name))
          }
        }
        _ -> Error(errors.InvalidInputType(def.name))
      }
    types.ExecutableConstList(vals) ->
      case def.named_type {
        types.ListType(_) ->
          vals
          |> list.fold_until(Ok(Nil), fn(acc, val) {
            case validate_value_to_def(val, def, type_map) {
              Ok(_) -> list.Continue(acc)
              Error(err) -> list.Stop(Error(err))
            }
          })
        _ -> Error(errors.InvalidInputType(def.name))
      }
  }
}

pub fn validate_scalar_type(
  scalar: types.ExecutableConstScalar,
  arg: types.ExecutableInputValueDef,
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaError) {
  case scalar, arg.named_type {
    types.ExecutableBoolVal(_), types.NamedType(t)
    | types.ExecutableFloatVal(_), types.NamedType(t)
    | types.ExecutableIntVal(_), types.NamedType(t)
    | types.ExecutableStringVal(_), types.NamedType(t)
    ->
      case type_map |> dict.get(t.name) {
        Ok(types.ScalarTypeDef(_)) -> Ok(Nil)
        Ok(_) -> Error(errors.InvalidInputType(t.name))
        Error(_) -> Error(errors.MissingType(t.name))
      }
    types.ExecutableEnumVal(val), types.NamedType(t) -> {
      case type_map |> dict.get(t.name) {
        Ok(types.EnumTypeDef(types.ExecutableEnumTypeDef(
          description: _,
          directives: _,
          name: _,
          members:,
        ))) -> {
          case members |> list.any(fn(member) { member.name == val }) {
            True -> Ok(Nil)
            False ->
              Error(errors.InvalidConstValueUsage(errors.InvalidEnumValue(val)))
          }
        }
        Ok(_) -> Error(errors.InvalidInputType(t.name))
        Error(_) -> Error(errors.MissingType(t.name))
      }
    }
    types.ExecutableNullVal, _ -> {
      use <- bool.guard(util.is_nullable(arg.named_type), Ok(Nil))
      Error(errors.InvalidConstValueUsage(errors.NullValueForNonNullType))
    }
    _, types.ListType(_) ->
      Error(errors.InvalidScalarType(get_scalar_name(arg.named_type)))
  }
}

pub fn validate_input_field_values(
  values: dict.Dict(String, types.ExecutableConstValue),
  fields: dict.Dict(String, types.ExecutableInputValueDef),
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaError) {
  fields
  |> dict.to_list
  |> list.fold_until(Ok(Nil), fn(acc, val) {
    let #(field_name, field) = val
    case values |> dict.get(field_name), util.is_nullable(field.named_type) {
      Ok(value), _ ->
        list.Continue(validate_value_to_def(value, field, type_map))
      _, True -> list.Continue(acc)
      _, _ -> list.Stop(Error(errors.MissingRequiredField(field_name)))
    }
  })
}

pub fn get_scalar_name(exec_type: types.ExecutableType) -> String {
  case exec_type {
    types.ListType(t) -> "[" <> t.executable_type |> get_scalar_name <> "]"
    types.NamedType(t) -> t.name
  }
}
