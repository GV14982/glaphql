import gleam/option
import internal/lexer/position
import internal/lexer/token

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

pub type InputValueDefinitions =
  option.Option(List(InputValueDefinitionNode))

pub type Document {
  OperationDocument(definitions: List(ExecutableDefinitionNode))
  SchemaDocument(definitions: List(TypeSystemDefinitionOrExtensionNode))
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
    location: position.Offset,
    operation: OperationType,
    named_type: NamedTypeNode,
  )
}

pub type TypeSystemDefinitionNode {
  TypeDefinitionNode(node: TypeDefinitionNode)
  SchemaDefinitionNode(node: SchemaDefinition)
  DirectiveDefinitionNode(node: DirectiveDefinition)
}

pub type SchemaDefinition {
  SchemaDefinition(
    description: OptionalDescription,
    location: position.Offset,
    directives: ConstDirectives,
    operation_types: List(RootOperationTypeDefinition),
  )
}

pub type DirectiveDefinition {
  DirectiveDefinition(
    description: OptionalDescription,
    name: NameNode,
    location: position.Offset,
    arguments: InputValueDefinitions,
    repeatable: Bool,
    locations: List(DirectiveLocationNode),
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

pub type DescriptionNode {
  DescriptionNode(value: String, location: position.Offset)
}

pub type TypeDefinitionNode {
  ScalarTypeDefinitionNode(node: ScalarTypeDefinition)
  ObjectTypeDefinitionNode(node: ObjectTypeDefinition)
  InterfaceTypeDefinitionNode(node: InterfaceTypeDefinition)
  UnionTypeDefinitionNode(node: UnionTypeDefinition)
  EnumTypeDefinitionNode(node: EnumTypeDefinition)
  InputTypeDefinitionNode(node: InputTypeDefinition)
}

pub type ScalarTypeDefinition {
  ScalarTypeDefinition(
    description: OptionalDescription,
    name: NameNode,
    location: position.Offset,
    directives: ConstDirectives,
  )
}

pub type ObjectTypeDefinition {
  ObjectTypeDefinition(
    description: OptionalDescription,
    name: NameNode,
    location: position.Offset,
    directives: ConstDirectives,
    interfaces: OptionalNamedTypeList,
    fields: FieldDefinitions,
  )
}

pub type InterfaceTypeDefinition {
  InterfaceTypeDefinition(
    description: OptionalDescription,
    name: NameNode,
    location: position.Offset,
    directives: ConstDirectives,
    interfaces: OptionalNamedTypeList,
    fields: FieldDefinitions,
  )
}

pub type UnionTypeDefinition {
  UnionTypeDefinition(
    description: OptionalDescription,
    name: NameNode,
    location: position.Offset,
    directives: ConstDirectives,
    members: OptionalNamedTypeList,
  )
}

pub type EnumTypeDefinition {
  EnumTypeDefinition(
    description: OptionalDescription,
    name: NameNode,
    location: position.Offset,
    directives: ConstDirectives,
    members: option.Option(List(EnumValueDefinitionNode)),
  )
}

pub type InputTypeDefinition {
  InputTypeDefinition(
    description: OptionalDescription,
    name: NameNode,
    directives: ConstDirectives,
    fields: InputValueDefinitions,
    location: position.Offset,
  )
}

pub type FieldDefinitionNode {
  FieldDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    location: position.Offset,
    directives: ConstDirectives,
    type_node: TypeNode,
    arguments: InputValueDefinitions,
  )
}

pub type InputValueDefinitionNode {
  InputValueDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    location: position.Offset,
    directives: ConstDirectives,
    type_node: TypeNode,
    default_value: option.Option(ConstValueNode),
  )
}

pub type EnumValueDefinitionNode {
  EnumValueDefinitionNode(
    description: OptionalDescription,
    name: NameNode,
    location: position.Offset,
    directives: ConstDirectives,
  )
}

pub type TypeSystemExtensionNode {
  SchemaExtensionNode(node: SchemaExtension)
  TypeExtensionNode(node: TypeExtensionNode)
}

pub type SchemaExtension {
  SchemaExtension(
    location: position.Offset,
    directives: ConstDirectives,
    operation_types: option.Option(List(RootOperationTypeDefinition)),
  )
}

pub type ObjectTypeExtension {
  ObjectTypeExtensionWithFields(
    name: NameNode,
    location: position.Offset,
    interfaces: OptionalNamedTypeList,
    directives: ConstDirectives,
    fields: List(FieldDefinitionNode),
  )
  ObjectTypeExtensionWithDirectives(
    name: NameNode,
    location: position.Offset,
    interfaces: OptionalNamedTypeList,
    directives: List(ConstDirectiveNode),
  )
  ObjectTypeExtensionWithInterfaces(
    name: NameNode,
    location: position.Offset,
    interfaces: List(NamedTypeNode),
  )
}

pub type EnumTypeExtension {
  EnumTypeExtensionWithMembers(
    name: NameNode,
    location: position.Offset,
    directives: ConstDirectives,
    members: List(EnumValueDefinitionNode),
  )
  EnumTypeExtensionWithoutMembers(
    name: NameNode,
    location: position.Offset,
    directives: List(ConstDirectiveNode),
  )
}

pub type InterfaceTypeExtension {
  InterfaceTypeExtensionWithFieldsNode(
    name: NameNode,
    location: position.Offset,
    interfaces: OptionalNamedTypeList,
    directives: ConstDirectives,
    fields: List(FieldDefinitionNode),
  )
  InterfaceTypeExtensionWithDirectivesNode(
    name: NameNode,
    location: position.Offset,
    interfaces: OptionalNamedTypeList,
    directives: List(ConstDirectiveNode),
  )
  InterfaceTypeExtensionWithImplementsNode(
    name: NameNode,
    location: position.Offset,
    interfaces: List(NamedTypeNode),
  )
}

pub type UnionTypeExtension {
  UnionTypeExtensionWithMembers(
    name: NameNode,
    location: position.Offset,
    directives: ConstDirectives,
    members: List(NamedTypeNode),
  )
  UnionTypeExtensionWithDirectives(
    name: NameNode,
    location: position.Offset,
    directives: List(ConstDirectiveNode),
  )
}

pub type InputTypeExtension {
  InputTypeExtensionWithFields(
    name: NameNode,
    location: position.Offset,
    directives: ConstDirectives,
    fields: List(InputValueDefinitionNode),
  )
  InputTypeExtensionWithDirectives(
    name: NameNode,
    location: position.Offset,
    directives: List(ConstDirectiveNode),
  )
}

pub type ScalarTypeExtension {
  ScalarTypeExtension(
    name: NameNode,
    location: position.Offset,
    directives: List(ConstDirectiveNode),
  )
}

pub type TypeExtensionNode {
  ScalarTypeExtensionNode(node: ScalarTypeExtension)
  ObjectTypeExtensionNode(node: ObjectTypeExtension)
  InterfaceTypeExtensionNode(node: InterfaceTypeExtension)
  UnionTypeExtensionNode(node: UnionTypeExtension)
  EnumTypeExtensionNode(node: EnumTypeExtension)
  InputObjectTypeExtensionNode(node: InputTypeExtension)
}
