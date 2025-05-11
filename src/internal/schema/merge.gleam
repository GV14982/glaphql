/// This module provides functions for merging type definitions and extensions
/// to create a complete executable schema.

import errors
import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import internal/parser/node
import internal/schema/type_system
import internal/schema/types

/// Merges schema definitions and extensions to create an executable schema
///
/// ## Arguments
///
/// - `ts`: Type system definitions and extensions
/// - `description`: Optional schema description
///
/// ## Returns
///
/// - `Ok(ExecutableSchema)`: The merged schema
/// - `Error(errors.SchemaError)`: If any errors occurred during merging
///
pub fn merge_schema(
  ts: types.TypeSystem,
  description: option.Option(String),
) -> Result(types.ExecutableSchema, errors.SchemaError) {
  use query <- result.try(type_system.get_root_operation(ts, node.Query))
  let mutation =
    type_system.get_root_operation(ts, node.Mutation) |> option.from_result
  let subscription =
    type_system.get_root_operation(ts, node.Subscription) |> option.from_result
  let def_directives =
    ts.defs.schema
    |> option.map(fn(o) { o.directives })
    |> option.flatten
    |> type_system.map_directives
  let ext_directives =
    ts.exts.schema
    |> list.flat_map(fn(ext) { ext.directives |> type_system.map_directives })
  let directives = def_directives |> list.append(ext_directives)
  Ok(types.ExecutableSchema(
    description:,
    query:,
    mutation:,
    subscription:,
    directives:,
    directive_defs: dict.new(),
    type_map: dict.new(),
  ))
}

pub fn merge_types(
  defs: dict.Dict(String, type_def_node),
  exts: dict.Dict(String, List(type_ext_node)),
  wrapper: fn(executable_type) -> types.ExecutableTypeDef,
  map_def_to_executable: fn(type_def_node, List(type_ext_node)) ->
    Result(executable_type, merge_error),
) -> Result(dict.Dict(String, types.ExecutableTypeDef), merge_error) {
  defs
  |> dict.to_list
  |> list.map(fn(def) {
    let #(name, node) = def
    let ext = exts |> dict.get(name) |> option.from_result
    map_def_to_executable(node, ext |> option.unwrap([]))
    |> result.map(fn(m) { #(name, wrapper(m)) })
  })
  |> result.all
  |> result.map(dict.from_list)
}

pub fn merge_scalar(
  def_node: node.ScalarTypeDefinition,
  ext_nodes: List(node.ScalarTypeExtension),
) -> Result(types.ExecutableScalarTypeDef, errors.SchemaError) {
  let ext_directives =
    ext_nodes
    |> list.map(fn(n) { n.directives })
    |> list.flatten
  Ok(types.ExecutableScalarTypeDef(
    description: def_node.description |> option.map(fn(d) { d.value }),
    name: def_node.name.value,
    directives: def_node.directives
      |> option.map(fn(def) { def |> list.append(ext_directives) })
      |> option.or(option.Some(ext_directives))
      |> type_system.map_directives,
  ))
}

pub fn merge_object(
  def_node: node.ObjectTypeDefinition,
  ext_nodes: List(node.ObjectTypeExtension),
) -> Result(types.ExecutableObjectTypeDef, errors.SchemaError) {
  let def =
    types.ExecutableObjectTypeDef(
      name: def_node.name.value,
      description: def_node.description |> option.map(fn(opt) { opt.value }),
      directives: def_node.directives |> type_system.map_directives,
      fields: def_node.fields |> type_system.map_fields,
      interfaces: def_node.interfaces
        |> option.unwrap([])
        |> list.map(fn(i) { i.name.value }),
    )
  use acc, curr <- list.try_fold(ext_nodes, def)
  case curr {
    node.ObjectTypeExtensionWithInterfaces(name: _, location: _, interfaces:) ->
      Ok(
        types.ExecutableObjectTypeDef(
          ..acc,
          interfaces: acc.interfaces
            |> list.append(interfaces |> list.map(fn(i) { i.name.value })),
        ),
      )
    node.ObjectTypeExtensionWithDirectives(
      name: _,
      location: _,
      interfaces:,
      directives:,
    ) ->
      Ok(
        types.ExecutableObjectTypeDef(
          ..acc,
          directives: acc.directives
            |> list.append(
              directives |> option.Some |> type_system.map_directives,
            ),
          interfaces: acc.interfaces
            |> list.append(
              interfaces
              |> option.map(fn(o) { o |> list.map(fn(i) { i.name.value }) })
              |> option.unwrap([]),
            ),
        ),
      )
    node.ObjectTypeExtensionWithFields(
      name: _,
      location: _,
      interfaces:,
      directives:,
      fields:,
    ) -> {
      let ext_fields = fields |> option.Some |> type_system.map_fields
      let conflicting_types =
        ext_fields
        |> dict.filter(fn(k, f) {
          let og = acc.fields |> dict.get(k)
          case og {
            Ok(og) -> og.named_type != f.named_type
            Error(_) -> False
          }
        })
      case conflicting_types |> dict.size {
        0 ->
          Ok(
            types.ExecutableObjectTypeDef(
              ..acc,
              fields: acc.fields
                |> dict.merge(ext_fields),
              directives: acc.directives
                |> list.append(directives |> type_system.map_directives),
              interfaces: acc.interfaces
                |> list.append(
                  interfaces
                  |> option.map(fn(o) { o |> list.map(fn(i) { i.name.value }) })
                  |> option.unwrap([]),
                ),
            ),
          )
        // TODO: Add error for conflicting types in object type extension fields
        _ -> Error(errors.InvalidObjectType)
      }
    }
  }
}

pub fn merge_input(
  def_node: node.InputTypeDefinition,
  ext_nodes: List(node.InputTypeExtension),
) -> Result(types.ExecutableInputTypeDef, errors.SchemaError) {
  let def =
    types.ExecutableInputTypeDef(
      name: def_node.name.value,
      description: def_node.description |> option.map(fn(d) { d.value }),
      directives: def_node.directives |> type_system.map_directives,
      fields: def_node.fields |> type_system.map_input_values,
    )
  use acc, curr <- list.try_fold(ext_nodes, def)
  case curr {
    node.InputTypeExtensionWithDirectives(name: _, location: _, directives:) ->
      Ok(
        types.ExecutableInputTypeDef(
          ..acc,
          directives: acc.directives
            |> list.append(
              directives |> option.Some |> type_system.map_directives,
            ),
        ),
      )
    node.InputTypeExtensionWithFields(
      name: _,
      location: _,
      directives:,
      fields:,
    ) -> {
      let ext_fields = fields |> option.Some |> type_system.map_input_values
      let conflicting_types =
        ext_fields
        |> dict.filter(fn(k, f) {
          let og = acc.fields |> dict.get(k)
          case og {
            Ok(og) -> og.named_type != f.named_type
            Error(_) -> False
          }
        })
      case conflicting_types |> dict.size {
        0 ->
          Ok(
            types.ExecutableInputTypeDef(
              ..acc,
              directives: acc.directives
                |> list.append(directives |> type_system.map_directives),
              fields: acc.fields |> dict.merge(ext_fields),
            ),
          )
        // TODO: Add error for conflicting types in object type extension fields
        _ -> Error(errors.InvalidInputType)
      }
    }
  }
}

pub fn merge_interface(
  def_node: node.InterfaceTypeDefinition,
  ext_nodes: List(node.InterfaceTypeExtension),
) -> Result(types.ExecutableInterfaceTypeDef, errors.SchemaError) {
  let def =
    types.ExecutableInterfaceTypeDef(
      name: def_node.name.value,
      description: def_node.description |> option.map(fn(d) { d.value }),
      directives: def_node.directives |> type_system.map_directives,
      fields: def_node.fields |> type_system.map_fields,
      interfaces: def_node.interfaces
        |> option.unwrap([])
        |> list.map(fn(i) { i.name.value }),
    )
  use acc, curr <- list.try_fold(ext_nodes, def)
  case curr {
    node.InterfaceTypeExtensionWithImplementsNode(
      name: _,
      location: _,
      interfaces:,
    ) ->
      Ok(
        types.ExecutableInterfaceTypeDef(
          ..acc,
          interfaces: acc.interfaces
            |> list.append(interfaces |> list.map(fn(i) { i.name.value })),
        ),
      )
    node.InterfaceTypeExtensionWithDirectivesNode(
      name: _,
      location: _,
      interfaces:,
      directives:,
    ) ->
      Ok(
        types.ExecutableInterfaceTypeDef(
          ..acc,
          directives: acc.directives
            |> list.append(
              directives |> option.Some |> type_system.map_directives,
            ),
          interfaces: acc.interfaces
            |> list.append(
              interfaces
              |> option.map(fn(o) { o |> list.map(fn(i) { i.name.value }) })
              |> option.unwrap([]),
            ),
        ),
      )
    node.InterfaceTypeExtensionWithFieldsNode(
      name: _,
      location: _,
      interfaces:,
      directives:,
      fields:,
    ) -> {
      let ext_fields = fields |> option.Some |> type_system.map_fields
      let conflicting_types =
        ext_fields
        |> dict.filter(fn(k, f) {
          let og = acc.fields |> dict.get(k)
          case og {
            Ok(og) -> og.named_type != f.named_type
            Error(_) -> False
          }
        })
      case conflicting_types |> dict.size {
        0 ->
          Ok(
            types.ExecutableInterfaceTypeDef(
              ..acc,
              fields: acc.fields
                |> dict.merge(ext_fields),
              directives: acc.directives
                |> list.append(directives |> type_system.map_directives),
              interfaces: acc.interfaces
                |> list.append(
                  interfaces
                  |> option.map(fn(o) { o |> list.map(fn(i) { i.name.value }) })
                  |> option.unwrap([]),
                ),
            ),
          )
        // TODO: Add error for conflicting types in object type extension fields
        _ -> Error(errors.InvalidInterfaceType)
      }
    }
  }
}

pub fn merge_union(
  def_node: node.UnionTypeDefinition,
  ext_nodes: List(node.UnionTypeExtension),
) -> Result(types.ExecutableUnionTypeDef, errors.SchemaError) {
  let def =
    types.ExecutableUnionTypeDef(
      name: def_node.name.value,
      description: def_node.description |> option.map(fn(d) { d.value }),
      directives: def_node.directives |> type_system.map_directives,
      members: def_node.members
        |> option.unwrap([])
        |> list.map(fn(m) { m.name.value }),
    )
  use acc, curr <- list.try_fold(ext_nodes, def)
  case curr {
    node.UnionTypeExtensionWithDirectives(name: _, location: _, directives:) ->
      Ok(
        types.ExecutableUnionTypeDef(
          ..acc,
          directives: acc.directives
            |> list.append(
              directives |> option.Some |> type_system.map_directives,
            ),
        ),
      )
    node.UnionTypeExtensionWithMembers(
      name: _,
      location: _,
      directives:,
      members:,
    ) ->
      Ok(
        types.ExecutableUnionTypeDef(
          ..acc,
          directives: acc.directives
            |> list.append(directives |> type_system.map_directives),
          members: acc.members
            |> list.append(members |> list.map(fn(m) { m.name.value })),
        ),
      )
  }
}

pub fn merge_enum(
  def_node: node.EnumTypeDefinition,
  ext_nodes: List(node.EnumTypeExtension),
) -> Result(types.ExecutableEnumTypeDef, errors.SchemaError) {
  let def =
    types.ExecutableEnumTypeDef(
      name: def_node.name.value,
      description: def_node.description |> option.map(fn(d) { d.value }),
      directives: def_node.directives |> type_system.map_directives,
      members: def_node.members |> type_system.map_enum_members,
    )
  use acc, curr <- list.try_fold(ext_nodes, def)
  case curr {
    node.EnumTypeExtensionWithoutMembers(name: _, location: _, directives:) ->
      Ok(
        types.ExecutableEnumTypeDef(
          ..acc,
          directives: acc.directives
            |> list.append(
              directives |> option.Some |> type_system.map_directives,
            ),
        ),
      )
    node.EnumTypeExtensionWithMembers(
      name: _,
      location: _,
      directives:,
      members:,
    ) ->
      Ok(
        types.ExecutableEnumTypeDef(
          ..acc,
          members: acc.members
            |> list.append(
              members |> option.Some |> type_system.map_enum_members,
            ),
          directives: acc.directives
            |> list.append(directives |> type_system.map_directives),
        ),
      )
  }
}
