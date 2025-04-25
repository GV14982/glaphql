import errors
import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import parser/node
import schema/types

@internal
pub fn from_schema_doc(doc: node.Document) -> Result(types.TypeSystem, Nil) {
  let type_system =
    types.TypeSystem(
      defs: types.TypeSystemDefinitionsByType(
        scalars: dict.new(),
        objects: dict.new(),
        inputs: dict.new(),
        interfaces: dict.new(),
        unions: dict.new(),
        enums: dict.new(),
        schema: option.None,
      ),
      exts: types.TypeSystemExtensionsByType(
        scalars: dict.new(),
        objects: dict.new(),
        inputs: dict.new(),
        interfaces: dict.new(),
        unions: dict.new(),
        enums: dict.new(),
        schema: [],
      ),
      directives: dict.new(),
    )
  // TODO: Propery handle this
  let assert node.SchemaDocument(defs) = doc
  Ok(
    defs
    |> list.fold(type_system, fn(acc, curr) {
      case curr {
        node.TypeSystemDefinitionNode(type_def_node) ->
          type_node(type_def_node, acc)
        node.TypeSystemExtensionNode(type_ext_node) ->
          type_ext(type_ext_node, acc)
      }
    }),
  )
}

@internal
pub fn type_ext(
  type_system_node: node.TypeSystemExtensionNode,
  acc: types.TypeSystem,
) -> types.TypeSystem {
  case type_system_node {
    node.TypeExtensionNode(type_node) ->
      case type_node {
        node.ScalarTypeExtensionNode(ext) ->
          types.TypeSystem(
            ..acc,
            exts: types.TypeSystemExtensionsByType(
              ..acc.exts,
              scalars: acc.exts.scalars
                |> dict.insert(ext.name.value, [
                  ext,
                  ..acc.exts.scalars
                  |> dict.get(ext.name.value)
                  |> result.unwrap([])
                ]),
            ),
          )
        node.ObjectTypeExtensionNode(ext) ->
          types.TypeSystem(
            ..acc,
            exts: types.TypeSystemExtensionsByType(
              ..acc.exts,
              objects: acc.exts.objects
                |> dict.insert(ext.name.value, [
                  ext,
                  ..acc.exts.objects
                  |> dict.get(ext.name.value)
                  |> result.unwrap([])
                ]),
            ),
          )
        node.InputObjectTypeExtensionNode(ext) ->
          types.TypeSystem(
            ..acc,
            exts: types.TypeSystemExtensionsByType(
              ..acc.exts,
              inputs: acc.exts.inputs
                |> dict.insert(ext.name.value, [
                  ext,
                  ..acc.exts.inputs
                  |> dict.get(ext.name.value)
                  |> result.unwrap([])
                ]),
            ),
          )
        node.InterfaceTypeExtensionNode(ext) ->
          types.TypeSystem(
            ..acc,
            exts: types.TypeSystemExtensionsByType(
              ..acc.exts,
              interfaces: acc.exts.interfaces
                |> dict.insert(ext.name.value, [
                  ext,
                  ..acc.exts.interfaces
                  |> dict.get(ext.name.value)
                  |> result.unwrap([])
                ]),
            ),
          )
        node.UnionTypeExtensionNode(ext) ->
          types.TypeSystem(
            ..acc,
            exts: types.TypeSystemExtensionsByType(
              ..acc.exts,
              unions: acc.exts.unions
                |> dict.insert(ext.name.value, [
                  ext,
                  ..acc.exts.unions
                  |> dict.get(ext.name.value)
                  |> result.unwrap([])
                ]),
            ),
          )
        node.EnumTypeExtensionNode(ext) ->
          types.TypeSystem(
            ..acc,
            exts: types.TypeSystemExtensionsByType(
              ..acc.exts,
              enums: acc.exts.enums
                |> dict.insert(ext.name.value, [
                  ext,
                  ..acc.exts.enums
                  |> dict.get(ext.name.value)
                  |> result.unwrap([])
                ]),
            ),
          )
      }
    node.SchemaExtensionNode(node.SchemaExtension(
      location:,
      directives:,
      operation_types:,
    )) ->
      types.TypeSystem(
        ..acc,
        exts: types.TypeSystemExtensionsByType(..acc.exts, schema: [
          node.SchemaExtension(location:, directives:, operation_types:),
          ..acc.exts.schema
        ]),
      )
  }
}

@internal
pub fn type_node(
  type_def_node: node.TypeSystemDefinitionNode,
  acc: types.TypeSystem,
) -> types.TypeSystem {
  case type_def_node {
    node.TypeDefinitionNode(type_node) -> {
      case type_node {
        node.ScalarTypeDefinitionNode(scalar) ->
          types.TypeSystem(
            ..acc,
            defs: types.TypeSystemDefinitionsByType(
              ..acc.defs,
              scalars: acc.defs.scalars
                |> dict.insert(scalar.name.value, scalar),
            ),
          )
        node.ObjectTypeDefinitionNode(object) ->
          types.TypeSystem(
            ..acc,
            defs: types.TypeSystemDefinitionsByType(
              ..acc.defs,
              objects: acc.defs.objects
                |> dict.insert(object.name.value, object),
            ),
          )
        node.InputTypeDefinitionNode(input) ->
          types.TypeSystem(
            ..acc,
            defs: types.TypeSystemDefinitionsByType(
              ..acc.defs,
              inputs: acc.defs.inputs
                |> dict.insert(input.name.value, input),
            ),
          )
        node.InterfaceTypeDefinitionNode(interface) ->
          types.TypeSystem(
            ..acc,
            defs: types.TypeSystemDefinitionsByType(
              ..acc.defs,
              interfaces: acc.defs.interfaces
                |> dict.insert(interface.name.value, interface),
            ),
          )
        node.UnionTypeDefinitionNode(union) ->
          types.TypeSystem(
            ..acc,
            defs: types.TypeSystemDefinitionsByType(
              ..acc.defs,
              unions: acc.defs.unions
                |> dict.insert(union.name.value, union),
            ),
          )
        node.EnumTypeDefinitionNode(enum) ->
          types.TypeSystem(
            ..acc,
            defs: types.TypeSystemDefinitionsByType(
              ..acc.defs,
              enums: acc.defs.enums
                |> dict.insert(enum.name.value, enum),
            ),
          )
      }
    }
    node.DirectiveDefinitionNode(node.DirectiveDefinition(name:, ..)) ->
      types.TypeSystem(
        ..acc,
        directives: acc.directives
          |> dict.insert(name.value, type_def_node),
      )
    node.SchemaDefinitionNode(node.SchemaDefinition(
      description:,
      location:,
      directives:,
      operation_types:,
    )) ->
      types.TypeSystem(
        ..acc,
        defs: types.TypeSystemDefinitionsByType(
          ..acc.defs,
          schema: option.Some(node.SchemaDefinition(
            description:,
            location:,
            directives:,
            operation_types:,
          )),
        ),
      )
  }
}

@internal
pub fn map_directives(
  directives: node.ConstDirectives,
) -> List(types.ExecutableDirective) {
  let directives =
    directives
    |> option.unwrap([])
  use directive <- list.map(directives)
  types.ExecutableDirective(name: directive.name.value, args: {
    let args =
      directive.arguments
      |> option.unwrap([])
    use acc, curr <- list.fold(args, dict.new())
    acc |> dict.insert(curr.name.value, curr.value |> map_const_value)
  })
}

@internal
pub fn map_fields(
  fields: node.FieldDefinitions,
) -> dict.Dict(String, types.ExecutableFieldDef) {
  use acc, curr <- list.fold(fields |> option.unwrap([]), dict.new())
  let name = curr.name.value
  let description = {
    use description <- option.map(curr.description)
    description.value
  }
  let args = dict.new()
  let directives = curr.directives |> map_directives

  let named_type = curr.type_node |> map_type_node
  acc
  |> dict.insert(
    curr.name.value,
    types.ExecutableFieldDef(
      name:,
      description:,
      args:,
      directives:,
      named_type:,
    ),
  )
}

@internal
pub fn map_input_values(
  fields: node.InputValueDefinitions,
) -> dict.Dict(String, types.ExecutableInputValueDef) {
  use acc, curr <- list.fold(fields |> option.unwrap([]), dict.new())
  let name = curr.name.value
  let description = {
    use description <- option.map(curr.description)
    description.value
  }
  let directives = curr.directives |> map_directives
  let named_type = curr.type_node |> map_type_node
  let default_value = curr.default_value |> option.map(map_const_value)
  acc
  |> dict.insert(
    curr.name.value,
    types.ExecutableInputValueDef(
      name:,
      description:,
      directives:,
      named_type:,
      default_value:,
    ),
  )
}

@internal
pub fn map_enum_members(
  members: option.Option(List(node.EnumValueDefinitionNode)),
) -> List(types.ExecutableEnumMember) {
  use member <- list.map(members |> option.unwrap([]))
  types.ExecutableEnumMember(
    name: member.name.value,
    description: member.description |> option.map(fn(opt) { opt.value }),
    directives: member.directives |> map_directives,
  )
}

@internal
pub fn map_named_type_nodes(
  named_type_nodes: option.Option(List(node.NamedTypeNode)),
) -> List(String) {
  use named_type_node <- list.map(named_type_nodes |> option.unwrap([]))
  named_type_node.name.value
}

@internal
pub fn map_type_node(type_node: node.TypeNode) -> types.ExecutableType {
  case type_node {
    node.NullableTypeNode(type_node:, ..) ->
      types.NamedType(types.ExecutableNamedType(
        name: type_node.name.value,
        nullable: True,
      ))
    node.NonNullTypeNode(type_node:, ..) ->
      types.NamedType(types.ExecutableNamedType(
        name: type_node.name.value,
        nullable: False,
      ))
    node.NonNullListTypeNode(type_node:, ..) ->
      types.ListType(types.ExecutableListType(
        executable_type: map_type_node(type_node),
        nullable: False,
      ))
    node.NullableListTypeNode(type_node:, ..) ->
      types.ListType(types.ExecutableListType(
        executable_type: map_type_node(type_node),
        nullable: True,
      ))
  }
}

@internal
pub fn map_const_value(
  const_val: node.ConstValueNode,
) -> types.ExecutableConstValue {
  case const_val {
    node.ConstValueNode(val) ->
      case val {
        node.BooleanValueNode(value:, location: _) ->
          types.ExecutableConstScalar(val: types.ExecutableBoolVal(value))
        node.StringValueNode(value:, location: _) ->
          types.ExecutableConstScalar(val: types.ExecutableStringVal(value))
        node.IntValueNode(value:, location: _) ->
          types.ExecutableConstScalar(val: types.ExecutableIntVal(value))
        node.FloatValueNode(value:, location: _) ->
          types.ExecutableConstScalar(val: types.ExecutableFloatVal(value))
        node.EnumValueNode(value:, location: _) ->
          types.ExecutableConstScalar(types.ExecutableEnumVal(value))
        node.NullValueNode(location: _) ->
          types.ExecutableConstScalar(types.ExecutableNullVal)
      }
    node.ConstObjectNode(values:, location: _) ->
      types.ExecutableConstObject(
        val: values
        |> list.map(fn(field) {
          #(field.name.value, map_const_value(field.value))
        })
        |> dict.from_list,
      )
    node.ConstListNode(values:, location: _) ->
      types.ExecutableConstList(val: values |> list.map(map_const_value))
  }
}

fn operation_type_to_string(op: node.OperationType) {
  case op {
    node.Query -> "Query"
    node.Mutation -> "Mutation"
    node.Subscription -> "Subscription"
  }
}

@internal
pub fn get_root_operation(
  ts: types.TypeSystem,
  op_name: node.OperationType,
) -> Result(types.ExecutableNamedType, errors.SchemaValidationError) {
  let schema_def =
    ts.defs.schema
    |> option.map(fn(def) {
      def.operation_types
      |> list.find(fn(o) { o.operation == op_name })
      |> option.from_result
    })
    |> option.flatten
  let schema_exts =
    ts.exts.schema
    |> list.filter_map(fn(ext) {
      case ext {
        node.SchemaExtension(
          directives: _,
          location: _,
          operation_types: option.Some(operation_types),
        ) -> Ok(operation_types)
        _ -> Error(Nil)
      }
    })
    |> list.flatten
  case schema_def {
    option.Some(def) -> {
      let type_names =
        [
          def.named_type.name.value,
          ..{
            schema_exts
            |> list.filter(fn(ext) { ext.operation == def.operation })
            |> list.map(fn(ext) { ext.named_type.name.value })
          }
        ]
        |> list.unique
      case type_names {
        [type_name] -> Ok(types.ExecutableNamedType(True, type_name))
        // TODO: Handle error if type changes a given root operation
        _ -> Error(errors.MissingQueryType)
      }
    }
    option.None -> {
      let type_names =
        schema_exts
        |> list.map(fn(ext) { ext.named_type.name.value })
        |> list.unique
      case type_names {
        [] -> {
          let has_ext_with_fields =
            ts.exts.objects
            |> dict.get(operation_type_to_string(op_name))
            |> result.map(fn(exts) {
              exts
              |> list.any(fn(ext) {
                case ext {
                  node.ObjectTypeExtensionWithFields(_, _, _, _, _) -> True
                  _ -> False
                }
              })
            })
            |> result.unwrap(False)
          let has_def =
            ts.defs.objects |> dict.has_key(operation_type_to_string(op_name))
          case has_def || has_ext_with_fields {
            True ->
              Ok(types.ExecutableNamedType(
                True,
                operation_type_to_string(op_name),
              ))
            False -> Error(errors.MissingQueryType)
          }
        }
        [type_name] -> Ok(types.ExecutableNamedType(True, type_name))
        // TODO: Handle error if type changes a given root operation
        _ -> Error(errors.MissingQueryType)
      }
    }
  }
}
