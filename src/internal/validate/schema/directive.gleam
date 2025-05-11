/// This module provides validation functions for GraphQL directives.
/// It ensures that directives are used correctly according to the GraphQL specification.

import errors
import gleam/bool
import gleam/dict
import gleam/list
import gleam/result
import internal/parser/node
import internal/schema/types
import internal/validate/schema/arg

/// Validates directives attached to a type definition
///
/// This function is a placeholder for future implementation.
pub fn validate_executable_type_def_directives(
  type_def: types.ExecutableTypeDef,
  directives: dict.Dict(String, types.ExecutableDirectiveDef),
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Nil {
  todo
}

/// Validates a list of directives at a specific location
///
/// Validates that:
/// 1. All directives are defined in the schema
/// 2. All directives are allowed at the specified location
/// 3. Non-repeatable directives are not used multiple times
/// 4. Directive arguments are valid
///
/// ## Arguments
///
/// - `directives`: List of directives to validate
/// - `location`: The location where these directives are being used
/// - `directive_def_map`: Dictionary of directive definitions
/// - `type_map`: Dictionary of all type definitions in the schema
///
/// ## Returns
///
/// - `Ok(Nil)`: If all directives are valid
/// - `Error(errors.SchemaError)`: If any validation error is found
///
pub fn validate_directives(
  directives: List(types.ExecutableDirective),
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

/// Validates a single directive
///
/// Validates that the directive is allowed at the specified location
/// and that its arguments are valid.
///
/// ## Arguments
///
/// - `directive`: The directive to validate
/// - `location`: The location where the directive is being used
/// - `def`: The directive definition
/// - `type_map`: Dictionary of all type definitions in the schema
///
/// ## Returns
///
/// - `Ok(Nil)`: If the directive is valid
/// - `Error(errors.SchemaError)`: If any validation error is found
///
pub fn validate_directive(
  directive: types.ExecutableDirective,
  location: node.DirectiveLocation,
  def: types.ExecutableDirectiveDef,
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.SchemaError) {
  use _ <- result.try(validate_directive_location(directive, location, def))
  arg.validate_arguments(directive.args, def.args, type_map)
}

/// Validates that a directive is allowed at the specified location
///
/// ## Arguments
///
/// - `directive`: The directive to validate
/// - `location`: The location where the directive is being used
/// - `def`: The directive definition
///
/// ## Returns
///
/// - `Ok(Nil)`: If the directive is allowed at the location
/// - `Error(errors.SchemaError)`: If the directive is not allowed at the location
///
pub fn validate_directive_location(
  directive: types.ExecutableDirective,
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
