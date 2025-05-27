//// This module provides functions to create executable GraphQL Operations
//// from the parsed document.

import errors
import gleam/bool
import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import internal/executable/schema/type_system
import internal/executable/types
import internal/parser/node
import internal/util

pub fn make_executable(
  input: node.Document,
  schema: types.ExecutableSchema,
  selected_operation: option.Option(String),
  variable_values: dict.Dict(String, types.ExecutableConstValue),
) -> Result(types.ExecutableOperationRequest, errors.OperationError) {
  let op_result = case input {
    node.OperationDocument(defs) -> {
      defs
      |> list.fold_until(
        Ok(types.ExecutableNamedOperationRequest(
          selected_operation: selected_operation |> option.unwrap(""),
          variable_values:,
          operations: dict.new(),
          fragments: dict.new(),
        )),
        fn(acc, curr) {
          let node_result = case curr {
            node.AnonymousOperationDefinitionNode(
              directives:,
              operation_type:,
              selection_set:,
              location: _,
            ) -> {
              case acc {
                Ok(types.ExecutableNamedOperationRequest(
                  operations:,
                  fragments:,
                  selected_operation: _,
                  variable_values: _,
                )) -> {
                  case operations |> dict.is_empty {
                    False -> Error(errors.NamedWithAnonymous)
                    True -> {
                      use <- bool.guard(
                        !schema_supports_operation(operation_type, schema),
                        Error(errors.OperationNotSupported(operation_type)),
                      )
                      let directive_result =
                        directives
                        |> option.unwrap([])
                        |> list.map(map_directive_to_executable)
                        |> result.all
                      use directives <- result.try(directive_result)
                      use selection_set <- result.try(
                        selection_set
                        |> map_selection_set_to_executable(
                          operation_type |> util.operation_type_to_string,
                          _,
                        ),
                      )
                      types.AnonymousExecutableOperation(
                        directives:,
                        operation_type:,
                        selection_set:,
                      )
                      |> types.ExecutableAnonymousOperationRequest(
                        fragments:,
                        operation: _,
                      )
                      |> Ok
                    }
                  }
                }
                acc -> acc
              }
            }
            node.NamedOperationDefinitionNode(
              name:,
              operation_type:,
              variable_definitions:,
              directives:,
              selection_set:,
              location: _,
            ) -> {
              case acc {
                Ok(types.ExecutableNamedOperationRequest(
                  fragments:,
                  operations:,
                  selected_operation:,
                  variable_values:,
                )) -> {
                  use <- bool.guard(
                    operations |> dict.has_key(name.value),
                    Error(errors.DuplicateOperationName(name.value)),
                  )
                  let variable_result =
                    variable_definitions
                    |> option.unwrap([])
                    |> list.fold_until(Ok(dict.new()), fn(acc, variable_def) {
                      let name = variable_def.variable_node.name.value
                      case acc {
                        Ok(acc) -> {
                          case acc |> dict.get(name) {
                            Error(_) ->
                              types.ExecutableVariableDefinition(
                                name:,
                                default_value: variable_def.default_value
                                  |> option.map(type_system.map_const_value),
                                variable_type: variable_def.type_node
                                  |> type_system.map_type_node,
                              )
                              |> dict.insert(acc, name, _)
                              |> Ok
                              |> list.Continue
                            Ok(_) ->
                              list.Stop(
                                Error(errors.DuplicateVariableName(name:)),
                              )
                          }
                        }
                        Error(err) -> list.Stop(Error(err))
                      }
                    })
                  use variables <- result.try(variable_result)
                  let directive_result =
                    directives
                    |> option.unwrap([])
                    |> list.map(map_directive_to_executable)
                    |> result.all
                  use directives <- result.try(directive_result)
                  use selection_set <- result.try(
                    selection_set
                    |> map_selection_set_to_executable(
                      operation_type |> util.operation_type_to_string,
                      _,
                    ),
                  )
                  let operations =
                    types.NamedExecutableOperation(
                      name: name.value,
                      directives:,
                      operation_type:,
                      selection_set:,
                      variables:,
                    )
                    |> dict.insert(operations, name.value, _)
                  types.ExecutableNamedOperationRequest(
                    fragments:,
                    operations:,
                    selected_operation:,
                    variable_values:,
                  )
                  |> Ok
                }
                Ok(types.ExecutableAnonymousOperationRequest(_, _)) ->
                  Error(errors.NamedWithAnonymous)
                acc -> acc
              }
            }
            node.FragmentDefinitionNode(
              name:,
              directives:,
              selection_set:,
              type_condition:,
              location: _,
            ) -> {
              use fragments <- result.try(get_fragments(acc))
              use <- bool.guard(
                fragments |> dict.has_key(name.value),
                Error(errors.DuplicateFragmentName(name.value)),
              )
              let directive_result =
                directives
                |> option.unwrap([])
                |> list.map(map_directive_to_executable)
                |> result.all
              use directives <- result.try(directive_result)
              use selection_set <- result.try(
                selection_set
                |> map_selection_set_to_executable(name.value, _),
              )
              types.ExecutableFragment(
                name: name.value,
                directives:,
                selection_set:,
                type_condition: type_condition.name.value,
              )
              |> dict.insert(fragments, name.value, _)
              |> merge_fragments(acc, _)
            }
          }
          case node_result {
            Ok(val) -> list.Continue(Ok(val))
            Error(err) -> list.Stop(Error(err))
          }
        },
      )
    }
    node.SchemaDocument(_) -> Error(errors.InvalidDocumentType)
  }
  use ops <- result.try(op_result)
  case ops {
    types.ExecutableAnonymousOperationRequest(operation:, fragments:) -> {
      use _ <- result.try(
        operation.selection_set
        |> list.map(validate_selection_fragments(_, fragments))
        |> result.all,
      )
      Ok(ops)
    }
    types.ExecutableNamedOperationRequest(
      operations:,
      fragments:,
      selected_operation:,
      variable_values:,
    ) -> {
      use <- bool.guard(
        selected_operation == "",
        errors.MissingSelectedOperation |> Error,
      )
      use operation <- result.try(
        operations
        |> dict.get(selected_operation)
        |> result.map_error(fn(_) {
          echo selected_operation
          errors.UndefinedOperation(selected_operation)
        }),
      )
      use _ <- result.try(
        operation.selection_set
        |> list.map(validate_selection_fragments(_, fragments))
        |> result.all,
      )
      use _ <- result.try(
        operation.variables
        |> dict.to_list
        |> list.map(fn(variable) {
          let #(name, variable) = variable
          let val =
            variable_values
            |> dict.get(name)
            |> result.lazy_unwrap(fn() {
              case variable.default_value {
                option.Some(val) -> val
                option.None ->
                  types.ExecutableConstScalar(types.ExecutableNullVal)
              }
            })
          validate_variable_value(val, variable.variable_type, schema)
        })
        |> result.all,
      )
      Ok(ops)
    }
  }
}

fn map_value_node_to_executable(val: node.ValueNode) -> types.ExecutableValue {
  case val {
    node.ListNode(values:, location: _) ->
      types.ExecutableList(values |> list.map(map_value_node_to_executable))
    node.ObjectNode(values:, location: _) ->
      types.ExecutableObject(
        values
        |> list.map(fn(field_node) {
          #(
            field_node.name.value,
            map_value_node_to_executable(field_node.value),
          )
        })
        |> dict.from_list,
      )
    node.ValueNode(node:) -> types.ExecutableScalar(type_system.map_const(node))
    node.Variable(node:) -> types.ExecutableVariable(name: node.name.value)
  }
}

fn map_directive_to_executable(
  directive: node.DirectiveNode,
) -> Result(types.ExecutableDirective, errors.OperationError) {
  let args_result =
    directive.arguments
    |> option.unwrap([])
    |> list.fold_until(Ok(dict.new()), fn(acc, curr) {
      case acc {
        Ok(acc) -> {
          case acc |> dict.get(curr.name.value) {
            Ok(_) ->
              list.Stop(
                errors.DuplicateArgumentName(name: curr.name.value)
                |> Error,
              )
            Error(_) -> {
              map_value_node_to_executable(curr.value)
              |> dict.insert(acc, curr.name.value, _)
              |> Ok
              |> list.Continue
            }
          }
        }
        Error(err) -> list.Stop(Error(err))
      }
    })
  use args <- result.try(args_result)
  types.ExecutableDirective(name: directive.name.value, args:)
  |> Ok
}

fn map_selection_set_to_executable(
  parent_name: String,
  selection: node.SelectionSetNode,
) -> Result(List(types.ExecutableSelection), errors.OperationError) {
  selection.selections
  |> list.fold_until(Ok(#(set.new(), [])), fn(acc, curr) {
    let selection_map_result = map_selection_to_executable(parent_name, curr)
    case selection_map_result, acc {
      Ok(selection), Ok(#(acc_set, execs)) -> {
        case selection {
          types.ExecutableField(executable_field) -> {
            let lookup =
              executable_field.alias |> option.unwrap(executable_field.name)
            case acc_set |> set.contains(lookup) {
              True ->
                list.Stop(
                  Error(errors.DuplicateFieldInSelectionSet(name: lookup)),
                )
              False ->
                #(acc_set |> set.insert(lookup), [
                  types.ExecutableField(executable_field),
                  ..execs
                ])
                |> Ok
                |> list.Continue
            }
          }
          types.ExecutableFragmentSpread(_, _)
          | types.ExecutableInlineFragment(_, _, _) ->
            #(acc_set, [selection, ..execs]) |> Ok |> list.Continue
        }
      }
      Error(err), _ -> list.Stop(Error(err))
      _, Error(err) -> list.Stop(Error(err))
    }
  })
  |> result.map(fn(val) { val.1 |> list.reverse })
}

fn map_selection_to_executable(
  parent_name: String,
  selection: node.SelectionNode,
) -> Result(types.ExecutableSelection, errors.OperationError) {
  case selection {
    node.FieldNode(
      name:,
      alias:,
      arguments: args,
      directives:,
      selection_set:,
      location: _,
    ) -> {
      let directive_result =
        directives
        |> option.unwrap([])
        |> list.map(map_directive_to_executable)
        |> result.all
      use directives <- result.try(directive_result)
      use args <- result.try(make_argument_executable(args))
      let alias =
        alias
        |> option.map(fn(alias_node) { alias_node.value })
      case selection_set {
        option.None ->
          types.ExecutableScalarField(
            name: name.value,
            alias:,
            directives:,
            args:,
          )
          |> types.ExecutableField
          |> Ok
        option.Some(selections) -> {
          use selection_set <- result.try(
            selections |> map_selection_set_to_executable(name.value, _),
          )
          types.ExecutableObjectField(
            name: name.value,
            alias:,
            directives:,
            selection_set:,
            args:,
          )
          |> types.ExecutableField
          |> Ok
        }
      }
    }
    node.FragmentSpreadNode(name:, directives:, location: _) -> {
      let directive_result =
        directives
        |> option.unwrap([])
        |> list.map(map_directive_to_executable)
        |> result.all
      use directives <- result.try(directive_result)
      types.ExecutableFragmentSpread(name: name.value, directives:) |> Ok
    }
    node.InlineFragmentNode(
      type_condition:,
      directives:,
      selection_set:,
      location: _,
    ) -> {
      let type_condition =
        type_condition
        |> option.map(fn(cond) { cond.name.value })
        |> option.unwrap(parent_name)
      let directive_result =
        directives
        |> option.unwrap([])
        |> list.map(map_directive_to_executable)
        |> result.all
      use directives <- result.try(directive_result)
      use selection <- result.try(
        selection_set |> map_selection_set_to_executable(type_condition, _),
      )
      types.ExecutableInlineFragment(type_condition:, directives:, selection:)
      |> Ok
    }
  }
}

fn schema_supports_operation(
  op: node.OperationType,
  schema: types.ExecutableSchema,
) -> Bool {
  case op {
    node.Mutation -> schema.mutation |> option.is_some
    node.Subscription -> schema.subscription |> option.is_some
    _ -> True
  }
}

fn get_fragments(
  exec: Result(types.ExecutableOperationRequest, errors.OperationError),
) -> Result(dict.Dict(String, types.ExecutableFragment), errors.OperationError) {
  case exec {
    Ok(val) ->
      case val {
        types.ExecutableAnonymousOperationRequest(fragments:, operation: _) ->
          fragments |> Ok
        types.ExecutableNamedOperationRequest(
          fragments:,
          operations: _,
          selected_operation: _,
          variable_values: _,
        ) -> fragments |> Ok
      }
    Error(err) -> Error(err)
  }
}

fn merge_fragments(
  res: Result(types.ExecutableOperationRequest, errors.OperationError),
  fragments: dict.Dict(String, types.ExecutableFragment),
) -> Result(types.ExecutableOperationRequest, errors.OperationError) {
  case res {
    Ok(val) ->
      case val {
        types.ExecutableAnonymousOperationRequest(fragments: _, operation:) ->
          types.ExecutableAnonymousOperationRequest(fragments:, operation:)
          |> Ok
        types.ExecutableNamedOperationRequest(
          fragments: _,
          operations:,
          selected_operation:,
          variable_values:,
        ) ->
          types.ExecutableNamedOperationRequest(
            fragments:,
            operations:,
            selected_operation:,
            variable_values:,
          )
          |> Ok
      }
    Error(err) -> Error(err)
  }
}

fn validate_selection_fragments(
  selection: types.ExecutableSelection,
  fragments: dict.Dict(String, types.ExecutableFragment),
) -> Result(Nil, errors.OperationError) {
  case selection {
    types.ExecutableFragmentSpread(name:, directives: _) ->
      case fragments |> dict.has_key(name) {
        False -> Error(errors.UndefinedFragment(name))
        True -> Ok(Nil)
      }
    types.ExecutableInlineFragment(selection:, directives: _, type_condition: _) ->
      selection
      |> list.map(validate_selection_fragments(_, fragments))
      |> result.all
      |> result.map(fn(_) { Nil })
    types.ExecutableField(_) -> Ok(Nil)
  }
}

fn make_argument_executable(
  args: node.Arguments,
) -> Result(dict.Dict(String, types.ExecutableArgument), errors.OperationError) {
  args
  |> option.unwrap([])
  |> list.fold_until(Ok(dict.new()), fn(acc, curr) {
    case acc {
      Ok(acc) -> {
        case acc |> dict.has_key(curr.name.value) {
          True ->
            list.Stop(Error(errors.DuplicateArgumentName(curr.name.value)))
          False -> {
            let value = map_value_node_to_executable(curr.value)
            let arg = types.ExecutableArgument(name: curr.name.value, value:)
            list.Continue(acc |> dict.insert(arg.name, arg) |> Ok)
          }
        }
      }
      err -> list.Stop(err)
    }
  })
}

fn validate_variable_value(
  val: types.ExecutableConstValue,
  variable_type: types.ExecutableType,
  schema: types.ExecutableSchema,
) -> Result(Nil, errors.OperationError) {
  case val, variable_type {
    types.ExecutableConstScalar(val),
      types.NamedType(types.ExecutableNamedType(nullable: _, name: _))
    -> validate_scalar_value(val, variable_type, schema.type_map)
    types.ExecutableConstList(vals),
      types.ListType(types.ExecutableListType(nullable: _, executable_type:))
    ->
      vals
      |> list.map(validate_variable_value(
        _,
        executable_type,
        // TODO: I'm not sure if this is quite what I want to do
        schema,
      ))
      |> result.all
      |> result.map(fn(_) { Nil })
    types.ExecutableConstObject(vals),
      types.NamedType(types.ExecutableNamedType(nullable: _, name:))
    -> {
      case schema.type_map |> dict.get(name) {
        Ok(types.InputTypeDef(types.ExecutableInputTypeDef(
          description: _,
          directives: _,
          name: _,
          fields:,
        ))) ->
          fields
          |> dict.values
          |> list.map(fn(field) {
            let field_val =
              vals
              |> dict.get(field.name)
              |> result.lazy_unwrap(fn() {
                case field.default_value {
                  option.Some(val) -> val
                  option.None ->
                    types.ExecutableConstScalar(types.ExecutableNullVal)
                }
              })
            validate_variable_value(field_val, field.named_type, schema)
          })
          |> result.all
          |> result.map(fn(_) { Nil })
        Error(_) -> Error(errors.UndefinedVariableType(name:))
        _ -> Error(errors.InvalidVariableType(name:))
      }
    }
    _, _ -> Error(errors.InvalidVariableValue(variable_type:, val:))
  }
}

fn validate_scalar_value(
  val: types.ExecutableConstScalar,
  scalar_type: types.ExecutableType,
  type_map: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.OperationError) {
  case val, scalar_type {
    types.ExecutableBoolVal(_),
      types.NamedType(types.ExecutableNamedType(nullable: _, name: "Boolean"))
    -> Ok(Nil)
    types.ExecutableFloatVal(_),
      types.NamedType(types.ExecutableNamedType(nullable: _, name: "Float"))
    -> Ok(Nil)
    types.ExecutableIntVal(_),
      types.NamedType(types.ExecutableNamedType(nullable: _, name: "Int"))
    -> Ok(Nil)
    types.ExecutableNullVal,
      types.NamedType(types.ExecutableNamedType(nullable: True, name: _))
    -> Ok(Nil)
    types.ExecutableStringVal(_),
      types.NamedType(types.ExecutableNamedType(nullable: _, name: "String"))
    -> Ok(Nil)
    types.ExecutableStringVal(_),
      types.NamedType(types.ExecutableNamedType(nullable: _, name: "ID"))
    | types.ExecutableIntVal(_),
      types.NamedType(types.ExecutableNamedType(nullable: _, name: "ID"))
    -> Ok(Nil)
    // TODO: Validate the type of the value
    _, types.NamedType(types.ExecutableNamedType(nullable: _, name:)) ->
      case type_map |> dict.get(name) {
        Ok(_) -> Ok(Nil)
        Error(_) -> Error(errors.UndefinedScalarType(name:))
      }
    _, types.ListType(_) -> Error(errors.InvalidListAsScalarType)
  }
}
