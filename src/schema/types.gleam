import gleam/dict
import gleam/option
import parser/node

@internal
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

@internal
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

@internal
pub type TypeSystem {
  TypeSystem(
    defs: TypeSystemDefinitionsByType,
    exts: TypeSystemExtensionsByType,
    directives: dict.Dict(String, node.TypeSystemDefinitionNode),
  )
}

@internal
pub type ExecutableSchema {
  ExecutableSchema(
    description: option.Option(String),
    query: ExecutableNamedType,
    mutation: option.Option(ExecutableNamedType),
    subscription: option.Option(ExecutableNamedType),
    type_map: dict.Dict(String, ExecutableTypeDef),
    directive_defs: dict.Dict(String, ExecutableDirectiveDef),
    directives: List(ExecutableDirective),
  )
}

@internal
pub type ExecutableTypeDef {
  ScalarTypeDef(ExecutableScalarTypeDef)
  EnumTypeDef(ExecutableEnumTypeDef)
  ObjectTypeDef(ExecutableObjectTypeDef)
  InputTypeDef(ExecutableInputTypeDef)
  InterfaceTypeDef(ExecutableInterfaceTypeDef)
  UnionTypeDef(ExecutableUnionTypeDef)
}

@internal
pub type ExecutableScalarTypeDef {
  ExecutableScalarTypeDef(
    name: String,
    description: option.Option(String),
    directives: List(ExecutableDirective),
  )
}

@internal
pub type ExecutableObjectTypeDef {
  ExecutableObjectTypeDef(
    name: String,
    description: option.Option(String),
    directives: List(ExecutableDirective),
    interfaces: List(String),
    fields: dict.Dict(String, ExecutableFieldDef),
  )
}

@internal
pub type ExecutableInterfaceTypeDef {
  ExecutableInterfaceTypeDef(
    name: String,
    description: option.Option(String),
    directives: List(ExecutableDirective),
    interfaces: List(String),
    fields: dict.Dict(String, ExecutableFieldDef),
  )
}

@internal
pub type ExecutableUnionTypeDef {
  ExecutableUnionTypeDef(
    name: String,
    description: option.Option(String),
    directives: List(ExecutableDirective),
    members: List(String),
  )
}

@internal
pub type ExecutableEnumTypeDef {
  ExecutableEnumTypeDef(
    name: String,
    description: option.Option(String),
    directives: List(ExecutableDirective),
    members: List(ExecutableEnumMember),
  )
}

@internal
pub type ExecutableEnumMember {
  ExecutableEnumMember(
    name: String,
    description: option.Option(String),
    directives: List(ExecutableDirective),
  )
}

@internal
pub type ExecutableInputTypeDef {
  ExecutableInputTypeDef(
    name: String,
    description: option.Option(String),
    directives: List(ExecutableDirective),
    fields: dict.Dict(String, ExecutableInputValueDef),
  )
}

@internal
pub type ExecutableInputValueDef {
  ExecutableInputValueDef(
    description: option.Option(String),
    name: String,
    named_type: ExecutableType,
    directives: List(ExecutableDirective),
    default_value: option.Option(ExecutableConstValue),
  )
}

@internal
pub type ExecutableFieldDef {
  ExecutableFieldDef(
    name: String,
    description: option.Option(String),
    named_type: ExecutableType,
    args: dict.Dict(String, ExecutableArgumentDef),
    directives: List(ExecutableDirective),
  )
}

@internal
pub type ExecutableType {
  NamedType(ExecutableNamedType)
  ListType(ExecutableListType)
}

@internal
pub type ExecutableNamedType {
  ExecutableNamedType(nullable: Bool, name: String)
}

@internal
pub type ExecutableListType {
  ExecutableListType(nullable: Bool, executable_type: ExecutableType)
}

@internal
pub type ExecutableConstValue {
  ExecutableConstScalar(val: ExecutableConstScalar)
  ExecutableConstObject(val: dict.Dict(String, ExecutableConstValue))
  ExecutableConstList(val: List(ExecutableConstValue))
}

@internal
pub type ExecutableConstScalar {
  ExecutableIntVal(Int)
  ExecutableFloatVal(Float)
  ExecutableStringVal(String)
  ExecutableBoolVal(Bool)
  ExecutableEnumVal(String)
  ExecutableNullVal
}

@internal
pub type ExecutableArgumentDef {
  ExecutableArgumentDef(
    name: String,
    description: option.Option(String),
    named_type: ExecutableType,
    default_value: option.Option(ExecutableConstValue),
    directives: List(ExecutableDirective),
  )
}

@internal
pub type ExecutableDirectiveDef {
  DirectiveDef(
    name: String,
    description: option.Option(String),
    args: dict.Dict(String, ExecutableInputValueDef),
    locations: List(node.DirectiveLocation),
    repeatable: Bool,
  )
}

@internal
pub type ExecutableDirective {
  ExecutableDirective(
    name: String,
    args: dict.Dict(String, ExecutableConstValue),
  )
}
