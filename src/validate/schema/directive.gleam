import errors
import gleam/bool
import gleam/dict
import gleam/list
import gleam/result
import parser/node
import schema/types
import validate/schema/arg

@internal
pub fn validate_executable_type_def_directives(
  type_def: types.ExecutableTypeDef,
  directives: dict.Dict(String, types.ExecutableDirectiveDef),
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Nil {
  todo
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
            case validate_directive(directive, location, def, type_map) {
              Ok(_) -> list.Continue(acc)
              Error(err) -> list.Stop(Error(err))
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
  use _ <- result.try(validate_directive_location(directive, location, def))
  arg.validate_arguments(directive.args, def.args, type_map)
}

@internal
pub fn validate_directive_location(
  directive: types.ExecutableDirective,
  location: node.DirectiveLocation,
  def: types.ExecutableDirectiveDef,
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
  Ok(Nil)
}
