import errors
import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import internal/executable/types
import internal/parser/node
import internal/util

pub type TypeSystemDefinitionsByType {
  TypeSystemDefinitionsByType(
    scalars: dict.Dict(String, node.ScalarTypeDefinition),
    objects: dict.Dict(String, node.ObjectTypeDefinition),
    inputs: dict.Dict(String, node.InputTypeDefinition),
    interfaces: dict.Dict(String, node.InterfaceTypeDefinition),
    unions: dict.Dict(String, node.UnionTypeDefinition),
    enums: dict.Dict(String, node.EnumTypeDefinition),
    schema: option.Option(node.SchemaDefinition),
  )
}

pub type TypeSystemExtensionsByType {
  TypeSystemExtensionsByType(
    scalars: dict.Dict(String, List(node.ScalarTypeExtension)),
    objects: dict.Dict(String, List(node.ObjectTypeExtension)),
    inputs: dict.Dict(String, List(node.InputTypeExtension)),
    interfaces: dict.Dict(String, List(node.InterfaceTypeExtension)),
    unions: dict.Dict(String, List(node.UnionTypeExtension)),
    enums: dict.Dict(String, List(node.EnumTypeExtension)),
    schema: List(node.SchemaExtension),
  )
}

pub type TypeSystem {
  TypeSystem(
    defs: TypeSystemDefinitionsByType,
    exts: TypeSystemExtensionsByType,
    directives: dict.Dict(String, node.TypeSystemDefinitionNode),
  )
}

pub fn from_schema_doc(doc: node.Document) -> Result(TypeSystem, Nil) {
  let type_system =
    TypeSystem(
      defs: TypeSystemDefinitionsByType(
        scalars: dict.new(),
        objects: dict.new(),
        inputs: dict.new(),
        interfaces: dict.new(),
        unions: dict.new(),
        enums: dict.new(),
        schema: option.None,
      ),
      exts: TypeSystemExtensionsByType(
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
  // Properly handle schema document parsing
  let assert node.SchemaDocument(defs) = doc
  defs
  |> list.try_fold(type_system, fn(acc, curr) {
    case curr {
      node.TypeSystemDefinitionNode(type_def_node) ->
        Ok(type_node(type_def_node, acc))
      node.TypeSystemExtensionNode(type_ext_node) ->
        Ok(type_ext(type_ext_node, acc))
    }
  })
}

pub fn type_ext(
  type_system_node: node.TypeSystemExtensionNode,
  acc: TypeSystem,
) -> TypeSystem {
  case type_system_node {
    node.TypeExtensionNode(type_node) ->
      case type_node {
        node.ScalarTypeExtensionNode(ext) ->
          TypeSystem(
            ..acc,
            exts: TypeSystemExtensionsByType(
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
          TypeSystem(
            ..acc,
            exts: TypeSystemExtensionsByType(
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
          TypeSystem(
            ..acc,
            exts: TypeSystemExtensionsByType(
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
          TypeSystem(
            ..acc,
            exts: TypeSystemExtensionsByType(
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
          TypeSystem(
            ..acc,
            exts: TypeSystemExtensionsByType(
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
          TypeSystem(
            ..acc,
            exts: TypeSystemExtensionsByType(
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
      TypeSystem(
        ..acc,
        exts: TypeSystemExtensionsByType(..acc.exts, schema: [
          node.SchemaExtension(location:, directives:, operation_types:),
          ..acc.exts.schema
        ]),
      )
  }
}

pub fn type_node(
  type_def_node: node.TypeSystemDefinitionNode,
  acc: TypeSystem,
) -> TypeSystem {
  case type_def_node {
    node.TypeDefinitionNode(type_node) -> {
      case type_node {
        node.ScalarTypeDefinitionNode(scalar) ->
          TypeSystem(
            ..acc,
            defs: TypeSystemDefinitionsByType(
              ..acc.defs,
              scalars: acc.defs.scalars
                |> dict.insert(scalar.name.value, scalar),
            ),
          )
        node.ObjectTypeDefinitionNode(object) ->
          TypeSystem(
            ..acc,
            defs: TypeSystemDefinitionsByType(
              ..acc.defs,
              objects: acc.defs.objects
                |> dict.insert(object.name.value, object),
            ),
          )
        node.InputTypeDefinitionNode(input) ->
          TypeSystem(
            ..acc,
            defs: TypeSystemDefinitionsByType(
              ..acc.defs,
              inputs: acc.defs.inputs
                |> dict.insert(input.name.value, input),
            ),
          )
        node.InterfaceTypeDefinitionNode(interface) ->
          TypeSystem(
            ..acc,
            defs: TypeSystemDefinitionsByType(
              ..acc.defs,
              interfaces: acc.defs.interfaces
                |> dict.insert(interface.name.value, interface),
            ),
          )
        node.UnionTypeDefinitionNode(union) ->
          TypeSystem(
            ..acc,
            defs: TypeSystemDefinitionsByType(
              ..acc.defs,
              unions: acc.defs.unions
                |> dict.insert(union.name.value, union),
            ),
          )
        node.EnumTypeDefinitionNode(enum) ->
          TypeSystem(
            ..acc,
            defs: TypeSystemDefinitionsByType(
              ..acc.defs,
              enums: acc.defs.enums
                |> dict.insert(enum.name.value, enum),
            ),
          )
      }
    }
    node.DirectiveDefinitionNode(node.DirectiveDefinition(name:, ..)) ->
      TypeSystem(
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
      TypeSystem(
        ..acc,
        defs: TypeSystemDefinitionsByType(
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

pub fn map_directives(
  directives: node.ConstDirectives,
) -> List(types.ExecutableConstDirective) {
  let directives =
    directives
    |> option.unwrap([])
  use directive <- list.map(directives)
  types.ExecutableConstDirective(name: directive.name.value, args: {
    let args =
      directive.arguments
      |> option.unwrap([])
    use acc, curr <- list.fold(args, dict.new())
    acc |> dict.insert(curr.name.value, curr.value |> map_const_value)
  })
}

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

pub fn map_named_type_nodes(
  named_type_nodes: option.Option(List(node.NamedTypeNode)),
) -> List(String) {
  use named_type_node <- list.map(named_type_nodes |> option.unwrap([]))
  named_type_node.name.value
}

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

pub fn map_const_value(
  const_val: node.ConstValueNode,
) -> types.ExecutableConstValue {
  case const_val {
    node.ConstValueNode(val) -> map_const(val) |> types.ExecutableConstScalar
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

pub fn map_const(val: node.ConstNode) -> types.ExecutableConstScalar {
  case val {
    node.BooleanValueNode(value:, location: _) -> types.ExecutableBoolVal(value)
    node.StringValueNode(value:, location: _) ->
      types.ExecutableStringVal(value)
    node.IntValueNode(value:, location: _) -> types.ExecutableIntVal(value)
    node.FloatValueNode(value:, location: _) -> types.ExecutableFloatVal(value)
    node.EnumValueNode(value:, location: _) -> types.ExecutableEnumVal(value)
    node.NullValueNode(location: _) -> types.ExecutableNullVal
  }
}

pub fn get_root_operation(
  ts: TypeSystem,
  op_name: node.OperationType,
) -> Result(types.ExecutableNamedType, errors.SchemaError) {
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
        _ -> Error(errors.InvalidRootOperationType)
      }
    }
    option.None -> {
      let type_names =
        schema_exts
        |> list.map(fn(ext) { ext.named_type.name.value })
        |> list.unique
      case type_names {
        [] -> {
          let op_type_name = util.operation_type_to_string(op_name)
          let has_ext_with_fields =
            ts.exts.objects
            |> dict.get(op_type_name)
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
            ts.defs.objects
            |> dict.has_key(op_type_name)
          case has_def || has_ext_with_fields {
            True -> Ok(types.ExecutableNamedType(True, op_type_name))
            False -> Error(errors.MissingQueryType)
          }
        }
        [type_name] -> Ok(types.ExecutableNamedType(True, type_name))
        _ -> Error(errors.InvalidRootOperationType)
      }
    }
  }
}
