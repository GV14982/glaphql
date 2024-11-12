import gleam/option
import lexer/position
import lexer/token

pub type NodeWithTokenList(a) =
  #(a, List(token.Token))

pub type Directives =
  option.Option(List(DirectiveNode))

pub type ConstDirectives =
  option.Option(List(ConstDirectiveNode))

pub type ConstArguments =
  option.Option(List(ConstArgumentNode))

pub type Arguments =
  option.Option(List(ArgumentNode))

pub type FieldDefinitions =
  option.Option(List(FieldDefinitionNode))

pub type OptionalDescription =
  option.Option(DescriptionNode)

pub type OptionalNamedTypeList =
  option.Option(List(NamedTypeNode))

pub type DocumentNode {
  ExecutableDocumentNode(definitions: List(ExecutableDefinitionNode))
  TypeSystemDocument(definitions: List(TypeSystemDefinitionOrExtensionNode))
}

pub type ExecutableDefinitionNode {
  OperationDefinitionNode(OperationDefinitionNode)
  FragmentDefinitionNode(
    name: NameNode,
    type_condition: NamedTypeNode,
    directives: Directives,
    selection_set: SelectionSetNode,
    location: position.Offset,
  )
}

pub type TypeSystemDefinitionOrExtensionNode {
  TypeSystemDefinitionNode(node: TypeSystemDefinitionNode)
  TypeSystemExtensionNode(node: TypeSystemExtensionNode)
}

pub type OperationDefinitionNode {
  QueryOperationNode(
    name: option.Option(NameNode),
    variable_definitions: option.Option(List(VariableDefinitionNode)),
    directives: Directives,
    selection_set: SelectionSetNode,
    location: position.Offset,
  )
  MutationOperationNode(
    name: NameNode,
    variable_definitions: option.Option(List(VariableDefinitionNode)),
    directives: Directives,
    selection_set: SelectionSetNode,
    location: position.Offset,
  )
  SubscriptionOperationNode(
    name: NameNode,
    variable_definitions: option.Option(List(VariableDefinitionNode)),
    directives: Directives,
    selection_set: SelectionSetNode,
    location: position.Offset,
  )
}

pub type SelectionSetNode {
  SelectionSetNode(selections: List(SelectionNode), location: position.Offset)
}

pub type SelectionNode {
  FieldNode(
    alias: option.Option(NameNode),
    name: NameNode,
    arguments: option.Option(List(ArgumentNode)),
    directives: Directives,
    selection_set: option.Option(SelectionSetNode),
    location: position.Offset,
  )
  FragmentSpreadNode(
    name: NameNode,
    directives: Directives,
    location: position.Offset,
  )
  InlineFragmentNode(
    type_condition: option.Option(NamedTypeNode),
    directives: Directives,
    selection_set: SelectionSetNode,
    location: position.Offset,
  )
}

pub type NullabilityAssertionNode {
  NonListNullabilityAssertionNode(node: NonListNullabilityAssertionNode)
  ListNullabilityAssertionNode(node: ListNullabilityOperatorNode)
}

pub type NonListNullabilityAssertionNode {
  NonNullAssertionNode(
    nullability_assertion: option.Option(ListNullabilityOperatorNode),
    location: position.Offset,
  )
  ErrorBoundaryNode(
    nullability_assertion: option.Option(ListNullabilityOperatorNode),
    location: position.Offset,
  )
}

pub type ListNullabilityOperatorNode {
  ListNullabilityOperatorNode(
    nullability_assertion: NullabilityAssertionNode,
    location: position.Offset,
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
    default_value: option.Option(ConstValueNode),
    directives: ConstDirectives,
    location: position.Offset,
  )
}

pub type VariableNode {
  VariableNode(name: NameNode, location: position.Offset)
}

pub type TypeNode {
  NullableTypeNode(type_node: NamedTypeNode, location: position.Offset)
  NonNullTypeNode(type_node: NamedTypeNode, location: position.Offset)
  NullableListTypeNode(type_node: TypeNode, location: position.Offset)
  NonNullListTypeNode(type_node: TypeNode, location: position.Offset)
}

pub type NamedTypeNode {
  NamedTypeNode(name: NameNode)
}

pub type ConstValueNode {
  ConstValueNode(node: ConstNode)
  ConstObjectNode(values: List(ConstObjectFieldNode), location: position.Offset)
  ConstListNode(values: List(ConstValueNode), location: position.Offset)
}

pub type ValueNode {
  Variable(node: VariableNode)
  ValueNode(node: ConstNode)
  ListNode(values: List(ValueNode), location: position.Offset)
  ObjectNode(values: List(ObjectFieldNode), location: position.Offset)
}

pub type ConstNode {
  IntValueNode(location: position.Offset, value: Int)
  FloatValueNode(location: position.Offset, value: Float)
  StringValueNode(location: position.Offset, value: String)
  BooleanValueNode(location: position.Offset, value: Bool)
  NullValueNode(location: position.Offset)
  EnumValueNode(location: position.Offset, value: String)
}

pub type ConstDirectiveNode {
  ConstDirectiveNode(
    name: NameNode,
    arguments: ConstArguments,
    location: position.Offset,
  )
}

pub type DirectiveNode {
  DirectiveNode(name: NameNode, arguments: Arguments, location: position.Offset)
}

pub type ConstArgumentNode {
  ConstArgumentNode(
    name: NameNode,
    value: ConstValueNode,
    location: position.Offset,
  )
}

pub type ArgumentNode {
  ArgumentNode(name: NameNode, value: ValueNode, location: position.Offset)
}

pub type ObjectFieldNode {
  ObjectFieldNode(name: NameNode, value: ValueNode, location: position.Offset)
}

pub type ConstObjectFieldNode {
  ConstObjectFieldNode(name: NameNode, value: ConstValueNode)
}

pub type NameNode {
  NameNode(value: String, location: position.Offset)
}

pub type RootOperationTypeDefinition {
  RootOperationTypeDefinition(
    operation: OperationType,
    named_type: NamedTypeNode,
    location: position.Offset,
  )
}

pub type TypeSystemDefinitionNode {
  SchemaDefinitionNode(
    description: OptionalDescription,
    directives: ConstDirectives,
    operation_types: List(RootOperationTypeDefinition),
    location: position.Offset,
  )
  TypeDefinitionNode(node: TypeDefinitionNode)
  DirectiveDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    arguments: ConstArguments,
    repeatable: Bool,
    locations: List(DirectiveLocationNode),
    location: position.Offset,
  )
}

pub type DirectiveLocationNode {
  DirectiveLocationNode(value: DirectiveLocation, location: position.Offset)
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
  DescriptionNode(value: String, location: position.Offset)
}

pub type TypeDefinitionNode {
  ScalarTypeDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    directives: ConstDirectives,
    location: position.Offset,
  )
  ObjectTypeDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    interfaces: OptionalNamedTypeList,
    directives: ConstDirectives,
    fields: FieldDefinitions,
    location: position.Offset,
  )
  InterfaceTypeDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    interfaces: OptionalNamedTypeList,
    directives: ConstDirectives,
    fields: FieldDefinitions,
    location: position.Offset,
  )
  UnionTypeDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    directives: ConstDirectives,
    members: OptionalNamedTypeList,
    location: position.Offset,
  )
  EnumTypeDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    directives: ConstDirectives,
    location: position.Offset,
    members: List(EnumValueDefinitionNode),
  )
  InputObjectTypeDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    directives: ConstDirectives,
    fields: option.Option(List(InputValueDefinitionNode)),
    location: position.Offset,
  )
}

pub type FieldDefinitionNode {
  FieldDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    arguments: option.Option(List(InputValueDefinitionNode)),
    type_node: TypeNode,
    directives: ConstDirectives,
    location: position.Offset,
  )
}

pub type InputValueDefinitionNode {
  InputValueDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    type_node: TypeNode,
    default_value: option.Option(ConstValueNode),
    directives: ConstDirectives,
    location: position.Offset,
  )
}

pub type EnumValueDefinitionNode {
  EnumValueDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    directives: ConstDirectives,
    location: position.Offset,
  )
}

pub type TypeSystemExtensionNode {
  SchemaExtensionNode(
    directives: ConstDirectives,
    operation_types: option.Option(List(RootOperationTypeDefinition)),
    location: position.Offset,
  )
  TypeExtensionNode(node: TypeExtensionNode)
}

pub type ObjectTypeExtension {
  ObjectTypeExtensionWithFields(
    name: NameNode,
    interfaces: OptionalNamedTypeList,
    directives: ConstDirectives,
    fields: List(FieldDefinitionNode),
    location: position.Offset,
  )
  ObjectTypeExtensionWithDirectives(
    name: NameNode,
    interfaces: OptionalNamedTypeList,
    directives: List(ConstDirectiveNode),
    location: position.Offset,
  )
  ObjectTypeExtensionWithInterfaces(
    name: NameNode,
    interfaces: List(NamedTypeNode),
    location: position.Offset,
  )
}

pub type EnumTypeExtensionNode {
  EnumTypeExtensionWithMembers(
    name: NameNode,
    directives: ConstDirectives,
    location: position.Offset,
    members: List(EnumValueDefinitionNode),
  )
  EnumTypeExtensionWithoutMembers(
    name: NameNode,
    directives: List(ConstDirectiveNode),
    location: position.Offset,
  )
}

pub type InterfaceTypeExtensionNode {
  InterfaceTypeExtensionWithFieldsNode(
    name: NameNode,
    interfaces: OptionalNamedTypeList,
    directives: ConstDirectives,
    fields: List(FieldDefinitionNode),
    location: position.Offset,
  )
  InterfaceTypeExtensionWithDirectivesNode(
    name: NameNode,
    interfaces: OptionalNamedTypeList,
    directives: List(ConstDirectiveNode),
    location: position.Offset,
  )
  InterfaceTypeExtensionWithImplementsNode(
    name: NameNode,
    interfaces: List(NamedTypeNode),
    location: position.Offset,
  )
}

pub type UnionTypeExtensionNode {
  UnionTypeExtensionWithMembers(
    name: NameNode,
    directives: ConstDirectives,
    members: List(NamedTypeNode),
    location: position.Offset,
  )
  UnionTypeExtensionWithDirectives(
    name: NameNode,
    directives: List(ConstDirectiveNode),
    location: position.Offset,
  )
}

pub type InputObjectTypeExtensionNode {
  InputObjectTypeExtensionWithFieldsNode(
    name: NameNode,
    directives: ConstDirectives,
    fields: List(InputValueDefinitionNode),
    location: position.Offset,
  )
  InputObjectTypeExtensionWithDirectivesNode(
    name: NameNode,
    directives: List(ConstDirectiveNode),
    location: position.Offset,
  )
}

pub type TypeExtensionNode {
  ScalarTypeExtensionNode(
    name: NameNode,
    directives: List(ConstDirectiveNode),
    location: position.Offset,
  )
  ObjectTypeExtensionNode(node: ObjectTypeExtension)
  InterfaceTypeExtensionNode(node: InterfaceTypeExtensionNode)
  UnionTypeExtensionNode(node: UnionTypeExtensionNode)
  EnumTypeExtensionNode(node: EnumTypeExtensionNode)
  InputObjectTypeExtensionNode(node: InputObjectTypeExtensionNode)
}
