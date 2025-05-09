import errors
import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import lexer/position
import parser/node
import schema/merge
import schema/type_system
import schema/types
import validate/schema as validate
import validate/schema/directive
import validate/schema/field
import validate/schema/interface
import validate/schema/union

@internal
pub fn from_types(
  ts: types.TypeSystem,
  description: option.Option(String),
) -> Result(types.ExecutableSchema, errors.SchemaValidationError) {
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
  use scalars <- result.try(merge.merge_types(
    ts.defs.scalars
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
    |> dict.to_list
    |> list.map(fn(d) {
      let #(name, directive) = d
      case directive {
        node.DirectiveDefinitionNode(node.DirectiveDefinition(
          name: _,
          description:,
          arguments:,
          locations:,
          repeatable:,
          location: _,
        )) -> {
          option.Some(types.DirectiveDef(
            name: name,
            description: description |> option.map(fn(d) { d.value }),
            args: arguments
              |> type_system.map_input_values,
            locations: locations |> list.map(fn(l) { l.value }),
            repeatable:,
          ))
        }
        _ -> option.None
      }
    })
    |> list.filter_map(fn(opt) {
      opt |> option.map(fn(d) { #(d.name, d) }) |> option.to_result(Nil)
    })
    |> dict.from_list
  // Check that all type names are unique
  use _ <- result.try(
    validate.check_unique_names([
      enums,
      scalars,
      objects,
      inputs,
      interfaces,
      unions,
    ]),
  )
  // Check interface impls
  use _ <- result.try(
    objects
    |> dict.merge(interfaces)
    |> dict.values
    |> list.map(interface.check_interface_implementations(_, interfaces))
    |> result.all
    |> result.map_error(errors.InvalidInterfaceImplementation),
  )
  use _ <- result.try(
    unions
    |> dict.values
    |> list.filter_map(is_executable_union)
    |> list.map(union.check_union_members(_, objects))
    |> result.all,
  )
  let type_map =
    enums
    |> dict.merge(scalars)
    |> dict.merge(objects)
    |> dict.merge(inputs)
    |> dict.merge(interfaces)
    |> dict.merge(unions)
  // TODO: Put this in a helper function
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
  Ok(types.ExecutableSchema(..executable_schema, directive_defs:, type_map:))
}

fn is_executable_union(
  type_def: types.ExecutableTypeDef,
) -> Result(types.ExecutableUnionTypeDef, Nil) {
  case type_def {
    types.UnionTypeDef(def) -> Ok(def)
    _ -> Error(Nil)
  }
}
