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
          arguments
          |> type_system.map_input_values
          option.Some(types.DirectiveDef(
            name: name,
            description: description |> option.map(fn(d) { d.value }),
            args: dict.new(),
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
    |> dict.to_list
    |> list.map(fn(val) {
      let #(_, obj) = val
      case obj {
        types.ObjectTypeDef(types.ExecutableObjectTypeDef(
          description: _,
          directives: _,
          fields: _,
          name: _,
          interfaces: interface_names,
        )) -> validate.check_interface_impls(interface_names, interfaces)
        // We should never get here because `objects` should only have object type defs in it
        _ -> Ok(Nil)
      }
    })
    |> result.all,
  )
  let type_map =
    enums
    |> dict.merge(scalars)
    |> dict.merge(objects)
    |> dict.merge(inputs)
    |> dict.merge(interfaces)
    |> dict.merge(unions)
  Ok(types.ExecutableSchema(..executable_schema, directive_defs:, type_map:))
}
