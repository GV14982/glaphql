import gleam/dict
import gleam/option
import internal/parser/node

pub type ExecutableSchema {
  ExecutableSchema(
    description: option.Option(String),
    query: ExecutableNamedType,
    mutation: option.Option(ExecutableNamedType),
    subscription: option.Option(ExecutableNamedType),
    type_map: dict.Dict(String, ExecutableTypeDef),
    directive_defs: dict.Dict(String, ExecutableDirectiveDef),
    directives: List(ExecutableConstDirective),
  )
}

pub type ExecutableTypeDef {
  ScalarTypeDef(ExecutableScalarTypeDef)
  EnumTypeDef(ExecutableEnumTypeDef)
  ObjectTypeDef(ExecutableObjectTypeDef)
  InputTypeDef(ExecutableInputTypeDef)
  InterfaceTypeDef(ExecutableInterfaceTypeDef)
  UnionTypeDef(ExecutableUnionTypeDef)
}

pub type ExecutableScalarTypeDef {
  ExecutableScalarTypeDef(
    name: String,
    description: option.Option(String),
    directives: List(ExecutableConstDirective),
  )
}

pub type ExecutableObjectTypeDef {
  ExecutableObjectTypeDef(
    name: String,
    description: option.Option(String),
    directives: List(ExecutableConstDirective),
    interfaces: List(String),
    fields: dict.Dict(String, ExecutableFieldDef),
  )
}

pub type ExecutableInterfaceTypeDef {
  ExecutableInterfaceTypeDef(
    name: String,
    description: option.Option(String),
    directives: List(ExecutableConstDirective),
    interfaces: List(String),
    fields: dict.Dict(String, ExecutableFieldDef),
  )
}

pub type ExecutableUnionTypeDef {
  ExecutableUnionTypeDef(
    name: String,
    description: option.Option(String),
    directives: List(ExecutableConstDirective),
    members: List(String),
  )
}

pub type ExecutableEnumTypeDef {
  ExecutableEnumTypeDef(
    name: String,
    description: option.Option(String),
    directives: List(ExecutableConstDirective),
    members: List(ExecutableEnumMember),
  )
}

pub type ExecutableEnumMember {
  ExecutableEnumMember(
    name: String,
    description: option.Option(String),
    directives: List(ExecutableConstDirective),
  )
}

pub type ExecutableInputTypeDef {
  ExecutableInputTypeDef(
    name: String,
    description: option.Option(String),
    directives: List(ExecutableConstDirective),
    fields: dict.Dict(String, ExecutableInputValueDef),
  )
}

pub type ExecutableInputValueDef {
  ExecutableInputValueDef(
    description: option.Option(String),
    name: String,
    named_type: ExecutableType,
    directives: List(ExecutableConstDirective),
    default_value: option.Option(ExecutableConstValue),
  )
}

pub type ExecutableFieldDef {
  ExecutableFieldDef(
    name: String,
    description: option.Option(String),
    named_type: ExecutableType,
    args: dict.Dict(String, ExecutableArgumentDef),
    directives: List(ExecutableConstDirective),
  )
}

pub type ExecutableType {
  NamedType(ExecutableNamedType)
  ListType(ExecutableListType)
}

pub type ExecutableNamedType {
  ExecutableNamedType(nullable: Bool, name: String)
}

pub type ExecutableListType {
  ExecutableListType(nullable: Bool, executable_type: ExecutableType)
}

pub type ExecutableConstValue {
  ExecutableConstScalar(val: ExecutableConstScalar)
  ExecutableConstObject(val: dict.Dict(String, ExecutableConstValue))
  ExecutableConstList(val: List(ExecutableConstValue))
}

pub type ExecutableConstScalar {
  ExecutableIntVal(Int)
  ExecutableFloatVal(Float)
  ExecutableStringVal(String)
  ExecutableBoolVal(Bool)
  ExecutableEnumVal(String)
  ExecutableNullVal
}

pub type ExecutableArgumentDef {
  ExecutableArgumentDef(
    name: String,
    description: option.Option(String),
    named_type: ExecutableType,
    default_value: option.Option(ExecutableConstValue),
    directives: List(ExecutableConstDirective),
  )
}

pub type ExecutableDirectiveDef {
  DirectiveDef(
    name: String,
    description: option.Option(String),
    args: dict.Dict(String, ExecutableInputValueDef),
    locations: List(node.DirectiveLocation),
    repeatable: Bool,
  )
}

pub type ExecutableConstDirective {
  ExecutableConstDirective(
    name: String,
    args: dict.Dict(String, ExecutableConstValue),
  )
}

pub type ExecutableOperationRequest {
  ExecutableNamedOperationRequest(
    selected_operation: String,
    variable_values: dict.Dict(String, ExecutableConstValue),
    operations: dict.Dict(String, NamedExecutableOperation),
    fragments: dict.Dict(String, ExecutableFragment),
  )
  ExecutableAnonymousOperationRequest(
    operation: AnonymousExecutableOperation,
    fragments: dict.Dict(String, ExecutableFragment),
  )
}

pub type AnonymousExecutableOperation {
  AnonymousExecutableOperation(
    operation_type: node.OperationType,
    selection_set: List(ExecutableSelection),
    directives: List(ExecutableDirective),
  )
}

pub type NamedExecutableOperation {
  NamedExecutableOperation(
    operation_type: node.OperationType,
    name: String,
    variables: dict.Dict(String, ExecutableVariableDefinition),
    directives: List(ExecutableDirective),
    selection_set: List(ExecutableSelection),
  )
}

pub type ExecutableFragment {
  ExecutableFragment(
    name: String,
    directives: List(ExecutableDirective),
    selection_set: List(ExecutableSelection),
    type_condition: String,
  )
}

pub type ExecutableVariableDefinition {
  ExecutableVariableDefinition(
    name: String,
    variable_type: ExecutableType,
    default_value: option.Option(ExecutableConstValue),
  )
}

pub type ExecutableDirective {
  ExecutableDirective(name: String, args: dict.Dict(String, ExecutableValue))
}

pub type ExecutableValue {
  ExecutableScalar(val: ExecutableConstScalar)
  ExecutableObject(val: dict.Dict(String, ExecutableValue))
  ExecutableList(val: List(ExecutableValue))
  ExecutableVariable(name: String)
}

pub type ExecutableSelection {
  ExecutableField(ExecutableField)
  ExecutableFragmentSpread(name: String, directives: List(ExecutableDirective))
  ExecutableInlineFragment(
    type_condition: String,
    directives: List(ExecutableDirective),
    selection: List(ExecutableSelection),
  )
}

pub type ExecutableField {
  ExecutableScalarField(
    name: String,
    alias: option.Option(String),
    directives: List(ExecutableDirective),
    args: dict.Dict(String, ExecutableArgument),
  )
  ExecutableObjectField(
    name: String,
    alias: option.Option(String),
    directives: List(ExecutableDirective),
    selection_set: List(ExecutableSelection),
    args: dict.Dict(String, ExecutableArgument),
  )
}

pub type ExecutableArgument {
  ExecutableArgument(name: String, value: ExecutableValue)
}
