import errors
import gleam/bool
import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import parser/node
import schema/types
import validate/util

@internal
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

@internal
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

@internal
pub fn check_interface_impls(
  interfaces: List(String),
  type_maps: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaValidationError) {
  let valid =
    interfaces
    |> list.all(fn(interface) {
      case type_maps |> dict.get(interface) {
        Ok(types.InterfaceTypeDef(_)) -> True
        _ -> False
      }
    })
  use <- bool.guard(valid, Ok(Nil))
  Error(errors.InvalidInterfaceImplementation)
}

@internal
pub fn check_union_members(
  members: List(String),
  type_maps: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaValidationError) {
  let valid =
    members
    |> list.all(fn(interface) {
      case type_maps |> dict.get(interface) {
        Ok(types.ObjectTypeDef(_)) -> True
        _ -> False
      }
    })
  use <- bool.guard(valid, Error(errors.InvalidUnionMember))
  Ok(Nil)
}

@internal
pub fn validate_directives(
  directives: List(types.ExecutableDirective),
  location: node.DirectiveLocation,
  directive_def_map: dict.Dict(String, types.ExecutableDirectiveDef),
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaValidationError) {
  directives
  |> list.group(fn(directive) { directive.name })
  |> dict.to_list
  |> list.fold_until(Ok(Nil), fn(acc, val) {
    let #(name, directive_list) = val
    case directive_def_map |> dict.get(name) {
      Ok(def) -> {
        case directive_list {
          [directive] -> {
            case def.locations |> list.contains(location) {
              True ->
                case validate_directive(directive, location, def, type_map) {
                  Ok(_) -> list.Continue(acc)
                  Error(err) -> list.Stop(Error(err))
                }
              False ->
                list.Stop(
                  Error(
                    errors.InvalidDirective(
                      errors.DirectiveNotSupportedAtLocation(def.name, location),
                    ),
                  ),
                )
            }
          }
          [directive, ..directives] -> {
            case def.repeatable {
              True ->
                case validate_directive(directive, location, def, type_map) {
                  Ok(_) ->
                    case
                      validate_directives(
                        directives,
                        location,
                        directive_def_map,
                        type_map,
                      )
                    {
                      Ok(_) -> list.Continue(acc)
                      Error(err) -> list.Stop(Error(err))
                    }
                  Error(err) -> list.Stop(Error(err))
                }
              False ->
                list.Stop(
                  Error(
                    errors.InvalidDirective(errors.DuplicateNonRepeatable(
                      def.name,
                    )),
                  ),
                )
            }
          }
          // TODO: Come up with a sort of "fallback error"
          [] -> list.Stop(Error(todo as "should never get here"))
        }
      }
      Error(_) ->
        list.Stop(
          Error(errors.InvalidDirective(errors.DirectiveNotDefined(name))),
        )
    }
  })
}

@internal
pub fn validate_directive(
  directive: types.ExecutableDirective,
  location: node.DirectiveLocation,
  def: types.ExecutableDirectiveDef,
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaValidationError) {
  use <- bool.guard(
    def.locations |> list.contains(location) |> bool.negate,
    Error(
      errors.InvalidDirective(errors.DirectiveNotSupportedAtLocation(
        directive.name,
        location,
      )),
    ),
  )
  validate_arguments(directive.args, def.args, type_map)
}

@internal
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
      Ok(def) -> list.Continue(validate_value_to_def(val, def, type_map))
      Error(_) ->
        list.Stop(Error(errors.InvalidArgument(errors.UndefinedArgument(name))))
    }
  })
}

fn validate_value_to_def(
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

fn validate_scalar_type(
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

fn validate_input_field_values(
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
      _, _ -> list.Stop(Error(todo))
    }
  })
}
