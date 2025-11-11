import errors
import gleam/bool
import gleam/dict
import gleam/list
import gleam/result
import internal/executable/types
import internal/parser/node
import internal/validate/schema/arg

pub fn validate_directives(
  directives: List(types.ExecutableConstDirective),
  location: node.DirectiveLocation,
  directive_def_map: dict.Dict(String, types.ExecutableDirectiveDef),
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaError) {
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
          // This is a fallback error, we should never get here
          [] ->
            list.Stop(
              Error(errors.InvalidDirective(errors.InvalidDirectiveList)),
            )
        }
      }
      Error(_) ->
        list.Stop(
          Error(errors.InvalidDirective(errors.DirectiveNotDefined(name))),
        )
    }
  })
}

pub fn validate_directive(
  directive: types.ExecutableConstDirective,
  location: node.DirectiveLocation,
  def: types.ExecutableDirectiveDef,
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaError) {
  use _ <- result.try(validate_directive_location(directive, location, def))
  arg.validate_arguments(directive.args, def.args, type_map)
}

pub fn validate_directive_location(
  directive: types.ExecutableConstDirective,
  location: node.DirectiveLocation,
  def: types.ExecutableDirectiveDef,
) -> Result(Nil, errors.SchemaError) {
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
