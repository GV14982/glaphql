/// This module provides functions to create an executable GraphQL schema
/// from the parsed type system definitions.
import errors
import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import internal/executable/schema/merge
import internal/executable/schema/type_system
import internal/executable/types
import internal/lexer/position
import internal/parser/node
import internal/validate/schema/directive
import internal/validate/schema/field
import internal/validate/schema/input_field
import internal/validate/schema/interface
import internal/validate/schema/names
import internal/validate/schema/union

/// Creates an executable schema from type system definitions
///
/// This function merges all type definitions and extensions, builds a complete
/// type map, and validates the schema according to the GraphQL specification.
///
/// ## Arguments
///
/// - `ts`: Type system definitions including objects, scalars, enums, etc.
/// - `description`: Optional schema description
///
/// ## Returns
///
/// - `Ok(ExecutableSchema)`: A valid executable schema
/// - `Error(errors.SchemaError)`: Validation errors encountered
///
pub fn from_types(
  ts: type_system.TypeSystem,
  description: option.Option(String),
) -> Result(types.ExecutableSchema, errors.SchemaError) {
  use executable_schema <- result.try(merge.merge_schema(ts, description))
  use enums <- result.try(merge.merge_types(
    ts.defs.enums,
    ts.exts.enums,
    types.EnumTypeDef,
    merge.merge_enum,
  ))
  // Setup a dict of the builtin GraphQL scalars
  let built_in_scalars =
    ["String", "Int", "Float", "Boolean", "ID"]
    |> list.fold(dict.new(), fn(acc, curr) {
      acc
      |> dict.insert(
        curr,
        node.ScalarTypeDefinition(
          description: option.None,
          name: node.NameNode(value: curr, location: #(
            position.new(),
            position.new(),
          )),
          directives: option.None,
          location: #(position.new(), position.new()),
        ),
      )
    })
  let built_in_directives =
    dict.new()
    |> dict.insert(
      "skip",
      types.DirectiveDef(
        name: "skip",
        description: option.None,
        repeatable: False,
        locations: [
          node.ExecutableDirectiveLocation(node.FieldDirective),
          node.ExecutableDirectiveLocation(node.FragmentSpreadDirective),
          node.ExecutableDirectiveLocation(node.InlineFragmentDirective),
        ],
        args: dict.new()
          |> dict.insert(
            "if",
            types.ExecutableInputValueDef(
              description: option.None,
              default_value: option.None,
              name: "if",
              named_type: types.NamedType(types.ExecutableNamedType(
                nullable: False,
                name: "Boolean",
              )),
              directives: [],
            ),
          ),
      ),
    )
    |> dict.insert(
      "include",
      types.DirectiveDef(
        name: "include",
        description: option.None,
        repeatable: False,
        locations: [
          node.ExecutableDirectiveLocation(node.FieldDirective),
          node.ExecutableDirectiveLocation(node.FragmentSpreadDirective),
          node.ExecutableDirectiveLocation(node.InlineFragmentDirective),
        ],
        args: dict.new()
          |> dict.insert(
            "if",
            types.ExecutableInputValueDef(
              description: option.None,
              default_value: option.None,
              name: "if",
              named_type: types.NamedType(types.ExecutableNamedType(
                nullable: False,
                name: "Boolean",
              )),
              directives: [],
            ),
          ),
      ),
    )
    |> dict.insert(
      "deprecated",
      types.DirectiveDef(
        name: "deprecated",
        description: option.None,
        repeatable: False,
        locations: [
          node.TypeSystemDirectiveLocation(node.FieldDefinitionDirective),
          node.TypeSystemDirectiveLocation(node.EnumValueDirective),
        ],
        args: dict.new()
          |> dict.insert(
            "reason",
            types.ExecutableInputValueDef(
              description: option.None,
              default_value: option.Some(
                types.ExecutableConstScalar(types.ExecutableStringVal(
                  "No longer supported",
                )),
              ),
              name: "reason",
              named_type: types.NamedType(types.ExecutableNamedType(
                nullable: True,
                name: "String",
              )),
              directives: [],
            ),
          ),
      ),
    )
    |> dict.insert(
      "specifiedBy",
      types.DirectiveDef(
        name: "specifiedBy",
        description: option.None,
        repeatable: False,
        locations: [node.TypeSystemDirectiveLocation(node.ScalarDirective)],
        args: dict.new()
          |> dict.insert(
            "url",
            types.ExecutableInputValueDef(
              description: option.None,
              default_value: option.None,
              name: "url",
              named_type: types.NamedType(types.ExecutableNamedType(
                nullable: False,
                name: "String",
              )),
              directives: [],
            ),
          ),
      ),
    )
  use scalars <- result.try(merge.merge_types(
    ts.defs.scalars
      // TODO: Rewrite this to bail on conflicting names
      |> dict.merge(built_in_scalars),
    ts.exts.scalars,
    types.ScalarTypeDef,
    merge.merge_scalar,
  ))
  use objects <- result.try(merge.merge_types(
    ts.defs.objects,
    ts.exts.objects,
    types.ObjectTypeDef,
    merge.merge_object,
  ))
  use inputs <- result.try(merge.merge_types(
    ts.defs.inputs,
    ts.exts.inputs,
    types.InputTypeDef,
    merge.merge_input,
  ))
  use unions <- result.try(merge.merge_types(
    ts.defs.unions,
    ts.exts.unions,
    types.UnionTypeDef,
    merge.merge_union,
  ))
  use interfaces <- result.try(merge.merge_types(
    ts.defs.interfaces,
    ts.exts.interfaces,
    types.InterfaceTypeDef,
    merge.merge_interface,
  ))
  let directive_defs =
    ts.directives
    |> dict.values
    // TODO: This should bail if conflicting name
    |> list.fold(built_in_directives, fn(acc, curr) {
      case curr {
        node.DirectiveDefinitionNode(node.DirectiveDefinition(
          name:,
          description:,
          arguments:,
          locations:,
          repeatable:,
          location: _,
        )) -> {
          let name = name.value
          types.DirectiveDef(
            name: name,
            description: description |> option.map(fn(d) { d.value }),
            args: arguments
              |> type_system.map_input_values,
            locations: locations |> list.map(fn(l) { l.value }),
            repeatable:,
          )
          |> dict.insert(acc, name, _)
        }
        _ -> acc
      }
    })
  // Validate that all type names are unique
  use _ <- result.try(
    names.validate_unique_names([
      enums,
      scalars,
      objects,
      inputs,
      interfaces,
      unions,
    ]),
  )
  // Validate interface implementations
  use _ <- result.try(
    objects
    |> dict.merge(interfaces)
    |> dict.values
    |> list.map(interface.validate_interface_implementations(_, interfaces))
    |> result.all
    |> result.map_error(errors.InvalidInterfaceImplementation),
  )
  // Validate union members
  use _ <- result.try(
    unions
    |> dict.values
    |> list.filter_map(is_executable_union)
    |> list.map(union.validate_union_members(_, objects))
    |> result.all,
  )
  let type_map =
    enums
    |> dict.merge(scalars)
    |> dict.merge(objects)
    |> dict.merge(inputs)
    |> dict.merge(interfaces)
    |> dict.merge(unions)
  // Validate directives
  let directive_validation_result =
    type_map
    |> dict.values
    |> list.map(fn(type_def) {
      case type_def {
        types.EnumTypeDef(def) -> {
          use _ <- result.try(directive.validate_directives(
            def.directives,
            node.TypeSystemDirectiveLocation(node.EnumDirective),
            directive_defs,
            type_map,
          ))
          def.members
          |> list.map(fn(member) {
            directive.validate_directives(
              member.directives,
              node.TypeSystemDirectiveLocation(node.EnumValueDirective),
              directive_defs,
              type_map,
            )
          })
          |> result.all
          |> result.map(fn(_) { Nil })
        }
        types.InputTypeDef(def) -> {
          use _ <- result.try(directive.validate_directives(
            def.directives,
            node.TypeSystemDirectiveLocation(node.InputObjectDirective),
            directive_defs,
            type_map,
          ))
          def.fields
          |> dict.values
          |> list.map(fn(field) {
            directive.validate_directives(
              field.directives,
              node.TypeSystemDirectiveLocation(
                node.InputFieldDefinitionDirective,
              ),
              directive_defs,
              type_map,
            )
          })
          |> result.all
          |> result.map(fn(_) { Nil })
        }
        types.InterfaceTypeDef(def) -> {
          use _ <- result.try(directive.validate_directives(
            def.directives,
            node.TypeSystemDirectiveLocation(node.InterfaceDirective),
            directive_defs,
            type_map,
          ))
          def.fields
          |> dict.values
          |> list.map(fn(field) {
            directive.validate_directives(
              field.directives,
              node.TypeSystemDirectiveLocation(node.FieldDefinitionDirective),
              directive_defs,
              type_map,
            )
          })
          |> result.all
          |> result.map(fn(_) { Nil })
        }
        types.ObjectTypeDef(def) -> {
          use _ <- result.try(directive.validate_directives(
            def.directives,
            node.TypeSystemDirectiveLocation(node.ObjectDirective),
            directive_defs,
            type_map,
          ))
          def.fields
          |> dict.values
          |> list.map(fn(field) {
            directive.validate_directives(
              field.directives,
              node.TypeSystemDirectiveLocation(node.FieldDefinitionDirective),
              directive_defs,
              type_map,
            )
          })
          |> result.all
          |> result.map(fn(_) { Nil })
        }
        types.ScalarTypeDef(def) ->
          directive.validate_directives(
            def.directives,
            node.TypeSystemDirectiveLocation(node.ScalarDirective),
            directive_defs,
            type_map,
          )
        types.UnionTypeDef(def) ->
          directive.validate_directives(
            def.directives,
            node.TypeSystemDirectiveLocation(node.UnionDirective),
            directive_defs,
            type_map,
          )
      }
    })
    |> result.all
  use _ <- result.try(directive_validation_result)
  // Validate output fields
  let field_validation_result =
    type_map
    |> dict.values
    |> list.filter_map(fn(def) {
      case def {
        types.InterfaceTypeDef(def) -> Ok(def.fields)
        types.ObjectTypeDef(def) -> Ok(def.fields)
        _ -> Error(Nil)
      }
    })
    |> list.map(field.validate_field_definitions(_, type_map))
    |> result.all
    |> result.map(fn(_) { Nil })
  use _ <- result.try(field_validation_result)
  // Validate input fields
  let input_field_validation_result =
    type_map
    |> dict.values
    |> list.filter_map(fn(def) {
      case def {
        types.InputTypeDef(def) -> Ok(def.fields)
        _ -> Error(Nil)
      }
    })
    |> list.map(input_field.validate_input_field_definitions(_, type_map))
    |> result.all
    |> result.map(fn(_) { Nil })
  use _ <- result.try(input_field_validation_result)
  Ok(types.ExecutableSchema(..executable_schema, directive_defs:, type_map:))
}

/// Safely extracts a union type definition from an executable type
///
/// ## Arguments
///
/// - `type_def`: An executable type definition
///
/// ## Returns
///
/// - `Ok(ExecutableUnionTypeDef)`: If the type is a union
/// - `Error(Nil)`: If the type is not a union
///
fn is_executable_union(
  type_def: types.ExecutableTypeDef,
) -> Result(types.ExecutableUnionTypeDef, Nil) {
  case type_def {
    types.UnionTypeDef(def) -> Ok(def)
    _ -> Error(Nil)
  }
}
