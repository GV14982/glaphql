import errors
import gleam/dict
import gleam/list
import internal/schema/types
import internal/validate/schema/value

pub fn validate_arguments(
  args: dict.Dict(String, types.ExecutableConstValue),
  arg_defs: dict.Dict(String, types.ExecutableInputValueDef),
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaValidationError) {
  args
  |> dict.to_list
  |> list.fold_until(Ok(Nil), fn(_, arg) {
    let #(name, val) = arg
    case arg_defs |> dict.get(name) {
      Ok(def) -> list.Continue(value.validate_value_to_def(val, def, type_map))
      Error(_) ->
        list.Stop(Error(errors.InvalidArgument(errors.UndefinedArgument(name))))
    }
  })
}
