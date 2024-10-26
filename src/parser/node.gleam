import gleam/option.{type Option}
import lexer/position.{type Offset}
import lexer/token.{type Token}

pub type NodeWithTokenList(a) =
  #(a, List(Token))

pub type Directives =
  Option(List(DirectiveNode))

pub type ConstDirectives =
  Option(List(ConstDirectiveNode))

pub type ConstArguments =
  Option(List(ConstArgumentNode))

pub type Arguments =
  Option(List(ArgumentNode))

pub type FieldDefinitions =
  Option(List(FieldDefinitionNode))

pub type OptionalDescription =
  Option(DescriptionNode)

pub type OptionalNamedTypeList =
  Option(List(NamedTypeNode))

pub type DocumentNode {
  Document(definitions: List(DefinitionNode))
  ExecutableDocumentNode(definitions: List(ExecutableDefinitionNode))
  TypeSystemDocument(definitions: List(TypeSystemDefinitionOrExtensionNode))
}

pub type DefinitionNode {
  ExecutableDefinitionNode(ExecutableDefinitionNode)
  TypeSystemNode(TypeSystemDefinitionOrExtensionNode)
}

pub type ExecutableDefinitionNode {
  OperationDefinitionNode(OperationDefinitionNode)
  FragmentDefinitionNode(
    name: NameNode,
    type_condition: NamedTypeNode,
    directives: Directives,
    selection_set: SelectionSetNode,
    location: Offset,
  )
}

pub type TypeSystemDefinitionOrExtensionNode {
  TypeSystemDefinitionNode(node: TypeSystemDefinitionNode)
  TypeSystemExtensionNode(node: TypeSystemExtensionNode)
}

pub type OperationDefinitionNode {
  QueryOperationNode(
    name: Option(NameNode),
    variable_definitions: Option(List(VariableDefinitionNode)),
    directives: Directives,
    selection_set: SelectionSetNode,
    location: Offset,
  )
  MutationOperationNode(
    name: NameNode,
    variable_definitions: Option(List(VariableDefinitionNode)),
    directives: Directives,
    selection_set: SelectionSetNode,
    location: Offset,
  )
  SubscriptionOperationNode(
    name: NameNode,
    variable_definitions: Option(List(VariableDefinitionNode)),
    directives: Directives,
    selection_set: SelectionSetNode,
    location: Offset,
  )
}

pub type SelectionSetNode {
  SelectionSetNode(selections: List(SelectionNode), location: Offset)
}

pub type SelectionNode {
  FieldNode(
    alias: Option(NameNode),
    name: NameNode,
    arguments: Option(List(ArgumentNode)),
    directives: Directives,
    selection_set: Option(SelectionSetNode),
    location: Offset,
  )
  FragmentSpreadNode(name: NameNode, directives: Directives, location: Offset)
  InlineFragmentNode(
    type_condition: Option(NamedTypeNode),
    directives: Directives,
    selection_set: SelectionSetNode,
    location: Offset,
  )
}

pub type NullabilityAssertionNode {
  NonListNullabilityAssertionNode(node: NonListNullabilityAssertionNode)
  ListNullabilityAssertionNode(node: ListNullabilityOperatorNode)
}

pub type NonListNullabilityAssertionNode {
  NonNullAssertionNode(
    nullability_assertion: Option(ListNullabilityOperatorNode),
    location: Offset,
  )
  ErrorBoundaryNode(
    nullability_assertion: Option(ListNullabilityOperatorNode),
    location: Offset,
  )
}

pub type ListNullabilityOperatorNode {
  ListNullabilityOperatorNode(
    nullability_assertion: NullabilityAssertionNode,
    location: Offset,
  )
}

pub type OperationType {
  Query
  Mutation
  Subscription
}

pub type VariableDefinitionNode {
  VariableDefinitionNode(
    variable_node: VariableNode,
    type_node: TypeNode,
    default_value: Option(ConstValueNode),
    directives: ConstDirectives,
    location: Offset,
  )
}

pub type VariableNode {
  VariableNode(name: NameNode, location: Offset)
}

pub type TypeNode {
  NullableTypeNode(type_node: NamedTypeNode, location: Offset)
  NonNullTypeNode(type_node: NamedTypeNode, location: Offset)
  NullableListTypeNode(type_node: TypeNode, location: Offset)
  NonNullListTypeNode(type_node: TypeNode, location: Offset)
}

pub type NamedTypeNode {
  NamedTypeNode(name: NameNode)
}

pub type ConstValueNode {
  ConstValueNode(node: ConstNode)
  ConstObjectNode(values: List(ConstObjectFieldNode), location: Offset)
  ConstListNode(values: List(ConstValueNode), location: Offset)
}

pub type ValueNode {
  Variable(node: VariableNode)
  ValueNode(node: ConstNode)
  ListNode(values: List(ValueNode), location: Offset)
  ObjectNode(values: List(ObjectFieldNode), location: Offset)
}

pub type ConstNode {
  IntValueNode(location: Offset, value: Int)
  FloatValueNode(location: Offset, value: Float)
  StringValueNode(location: Offset, value: String)
  BooleanValueNode(location: Offset, value: Bool)
  NullValueNode(location: Offset)
  EnumValueNode(location: Offset, value: String)
}

pub type ConstDirectiveNode {
  ConstDirectiveNode(
    name: NameNode,
    arguments: ConstArguments,
    location: Offset,
  )
}

pub type DirectiveNode {
  DirectiveNode(name: NameNode, arguments: Arguments, location: Offset)
}

pub type ConstArgumentNode {
  ConstArgumentNode(name: NameNode, value: ConstValueNode, location: Offset)
}

pub type ArgumentNode {
  ArgumentNode(name: NameNode, value: ValueNode, location: Offset)
}

pub type ObjectFieldNode {
  ObjectFieldNode(name: NameNode, value: ValueNode, location: Offset)
}

pub type ConstObjectFieldNode {
  ConstObjectFieldNode(name: NameNode, value: ConstValueNode)
}

pub type NameNode {
  NameNode(value: String, location: Offset)
}

pub type RootOperationTypeDefinition {
  RootOperationTypeDefinition(
    operation: OperationType,
    named_type: NamedTypeNode,
    location: Offset,
  )
}

pub type TypeSystemDefinitionNode {
  SchemaDefinitionNode(
    description: OptionalDescription,
    directives: ConstDirectives,
    operation_types: List(RootOperationTypeDefinition),
    location: Offset,
  )
  TypeDefinitionNode(node: TypeDefinitionNode)
  DirectiveDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    arguments: ConstArguments,
    repeatable: Bool,
    locations: List(DirectiveLocationNode),
    location: Offset,
  )
}

pub type DirectiveLocationNode {
  DirectiveLocationNode(value: DirectiveLocation, location: Offset)
}

pub type DirectiveLocation {
  ExecutableDirectiveLocation(ExecutableDirectiveLocation)
  TypeSystemDirectiveLocation(TypeSystemDirectiveLocation)
}

pub type ExecutableDirectiveLocation {
  QueryDirective
  MutationDirective
  SubscriptionDirective
  FieldDirective
  FragmentDefinitionDirective
  FragmentSpreadDirective
  InlineFragmentDirective
  VariableDefinitionDirective
}

pub type TypeSystemDirectiveLocation {
  SchemaDirective
  ScalarDirective
  ObjectDirective
  FieldDefinitionDirective
  ArgumentDefinitionDirective
  InterfaceDirective
  UnionDirective
  EnumDirective
  EnumValueDirective
  InputObjectDirective
  InputFieldDefinitionDirective
}

// TODO: Don't use a dedicated node for this... Find out how to pull the StringValueNode into the type level
pub type DescriptionNode {
  DescriptionNode(value: String, location: Offset)
}

pub type TypeDefinitionNode {
  ScalarTypeDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    directives: ConstDirectives,
    location: Offset,
  )
  ObjectTypeDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    interfaces: OptionalNamedTypeList,
    directives: ConstDirectives,
    fields: FieldDefinitions,
    location: Offset,
  )
  InterfaceTypeDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    interfaces: OptionalNamedTypeList,
    directives: ConstDirectives,
    fields: FieldDefinitions,
    location: Offset,
  )
  UnionTypeDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    directives: ConstDirectives,
    members: OptionalNamedTypeList,
    location: Offset,
  )
  EnumTypeDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    directives: ConstDirectives,
    location: Offset,
    members: List(EnumValueDefinitionNode),
  )
  InputObjectTypeDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    directives: ConstDirectives,
    fields: Option(List(InputValueDefinitionNode)),
    location: Offset,
  )
}

pub type FieldDefinitionNode {
  FieldDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    arguments: Option(List(InputValueDefinitionNode)),
    type_node: TypeNode,
    directives: ConstDirectives,
    location: Offset,
  )
}

pub type InputValueDefinitionNode {
  InputValueDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    type_node: TypeNode,
    default_value: Option(ConstValueNode),
    directives: ConstDirectives,
    location: Offset,
  )
}

pub type EnumValueDefinitionNode {
  EnumValueDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    directives: ConstDirectives,
    location: Offset,
  )
}

pub type TypeSystemExtensionNode {
  SchemaExtensionNode(
    directives: ConstDirectives,
    operation_types: Option(List(RootOperationTypeDefinition)),
    location: Offset,
  )
  TypeExtensionNode(node: TypeExtensionNode)
}

pub type ObjectTypeExtension {
  ObjectTypeExtensionWithFields(
    name: NameNode,
    interfaces: OptionalNamedTypeList,
    directives: ConstDirectives,
    fields: List(FieldDefinitionNode),
    location: Offset,
  )
  ObjectTypeExtensionWithDirectives(
    name: NameNode,
    interfaces: OptionalNamedTypeList,
    directives: List(ConstDirectiveNode),
    location: Offset,
  )
  ObjectTypeExtensionWithInterfaces(
    name: NameNode,
    interfaces: List(NamedTypeNode),
    location: Offset,
  )
}

pub type EnumTypeExtensionNode {
  EnumTypeExtensionWithMembers(
    name: NameNode,
    directives: ConstDirectives,
    location: Offset,
    members: List(EnumValueDefinitionNode),
  )
  EnumTypeExtensionWithoutMembers(
    name: NameNode,
    directives: List(ConstDirectiveNode),
    location: Offset,
  )
}

pub type InterfaceTypeExtensionNode {
  InterfaceTypeExtensionWithFieldsNode(
    name: NameNode,
    interfaces: OptionalNamedTypeList,
    directives: ConstDirectives,
    fields: List(FieldDefinitionNode),
    location: Offset,
  )
  InterfaceTypeExtensionWithDirectivesNode(
    name: NameNode,
    interfaces: OptionalNamedTypeList,
    directives: List(ConstDirectiveNode),
    location: Offset,
  )
  InterfaceTypeExtensionWithImplementsNode(
    name: NameNode,
    interfaces: List(NamedTypeNode),
    location: Offset,
  )
}

pub type UnionTypeExtensionNode {
  UnionTypeExtensionWithMembers(
    name: NameNode,
    directives: ConstDirectives,
    members: List(NamedTypeNode),
    location: Offset,
  )
  UnionTypeExtensionWithDirectives(
    name: NameNode,
    directives: List(ConstDirectiveNode),
    location: Offset,
  )
}

pub type InputObjectTypeExtensionNode {
  InputObjectTypeExtensionWithFieldsNode(
    name: NameNode,
    directives: ConstDirectives,
    fields: List(InputValueDefinitionNode),
    location: Offset,
  )
  InputObjectTypeExtensionWithDirectivesNode(
    name: NameNode,
    directives: List(ConstDirectiveNode),
    location: Offset,
  )
}

pub type TypeExtensionNode {
  ScalarTypeExtensionNode(
    name: NameNode,
    directives: List(ConstDirectiveNode),
    location: Offset,
  )
  ObjectTypeExtensionNode(node: ObjectTypeExtension)
  InterfaceTypeExtensionNode(node: InterfaceTypeExtensionNode)
  UnionTypeExtensionNode(node: UnionTypeExtensionNode)
  EnumTypeExtensionNode(node: EnumTypeExtensionNode)
  InputObjectTypeExtensionNode(node: InputObjectTypeExtensionNode)
}
