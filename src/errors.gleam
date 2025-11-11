import internal/executable/types
import internal/lexer/position
import internal/parser/node

pub type LexError {
  InvalidCharacter(value: String, pos: position.Position)
  InvalidNumber(value: String, pos: position.Position)
  UnterminatedString(value: String, pos: position.Position)
}

pub type ParseError {
  LexError(LexError)
  InvalidDefinition
  InvalidVariableDefinition
  InvalidDescription
  InvalidInputValueDefinition
  InvalidDefaultValue
  InvalidSchemaDefinition
  InvalidSchemaExtension
  InvalidScalarDefinition
  InvalidScalarExtension
  InvalidEnumDefinition
  InvalidEnumMember
  InvalidEnumExtension
  InvalidUnionDefinition
  InvalidUnionExtension
  InvalidInterfaceDefinition
  InvalidInterfaceExtension
  EmptyTokenList
  InvalidIntValue
  InvalidFloatValue
  InvalidConstArgument
  InvalidConstValue
  InvalidObjectField
  InvalidFieldDefinition
  InvalidTypeSystemDefinition
  InvalidTypeSystemExtension
  InvalidObjectTypeDefinition
  InvalidObjectTypeExtension
  InvalidValue
  InvalidSelectionSet
  InvalidField
  InvalidOperationType(String)
  InvalidOperationDef
  InvalidFragmentDef
  InvalidExecutableDef
  InvalidArgList
  InvalidArgDef
  InvalidRootOperation
  DuplicateRootOperationDefinition
  InvalidImplementsList
  InvalidInputTypeExtension
  InvalidInputTypeDefinition
  InvalidInputValueList
  InvalidDirectiveDefinition
  InvalidDirectiveLocation
}

pub fn map_lex_to_parse_error(err: LexError) -> ParseError {
  LexError(err)
}

pub type SchemaError {
  MissingQueryType
  NameCollision(name: String)
  MissingType(name: String)
  InvalidRootOperationType
  InvalidArgument(error: ArgumentError)
  InvalidConstValueUsage(error: ConstValueError)
  InvalidScalarType(name: String)
  InvalidObjectType(name: String)
  InvalidInputType(name: String)
  InvalidInterfaceType(name: String)
  InvalidUnionType(name: String)
  InvalidEnumType(name: String)
  InvalidInterfaceImplementation(error: InterfaceImplementationError)
  InvalidUnionMember(error: UnionMemberError)
  InvalidDirective(error: DirectiveError)
  InvalidInputField(error: FieldError)
  InvalidOutputField(error: FieldError)
  MissingRequiredField(name: String)
}

pub type InterfaceImplementationError {
  NonUniqueInterfaceList(name: String)
  UndefinedInterface(name: String)
  ImplementsNonInterface(name: String)
  CyclicInterfaceReference(name: String)
  IncompleteInterfaceImplementation(name: String)
  MissingFields(name: String, fields: List(String))
  IncorrectFieldType(
    name: String,
    field: String,
    expected_type: types.ExecutableType,
    found_type: types.ExecutableType,
  )
}

pub type UnionMemberError {
  UndefinedMember(name: String, member: String)
  NonObjectMember(name: String, member: String)
}

pub type ConstValueError {
  InvalidEnumValue(value: String)
  NullValueForNonNullType
}

pub type ArgumentError {
  UndefinedArgument(name: String)
}

pub type ScalarError

pub type DirectiveError {
  DuplicateNonRepeatable(directive_name: String)
  DirectiveNotSupportedAtLocation(
    directive_name: String,
    location: node.DirectiveLocation,
  )
  DirectiveNotDefined(directive_name: String)
  // This is a fallback error, should never happen
  InvalidDirectiveList
}

pub type FieldError {
  UndefinedFieldType(name: String)
  InvalidFieldType(name: String)
}

pub type OperationError {
  InvalidDocumentType
  OperationNotSupported(node.OperationType)
  DuplicateVariableName(name: String)
  DuplicateArgumentName(name: String)
  DuplicateFragmentName(name: String)
  DuplicateOperationName(name: String)
  DuplicateFieldInSelectionSet(name: String)
  NamedWithAnonymous
  UndefinedOperation(name: String)
  UndefinedFragment(name: String)
  MissingSelectedOperation
  MissingRequiredVariable
  UndefinedVariableType(name: String)
  InvalidVariableType(name: String)
  InvalidVariableValue(
    variable_type: types.ExecutableType,
    val: types.ExecutableConstValue,
  )
  UndefinedScalarType(name: String)
  InvalidListAsScalarType
}

pub type VariableDefinitionError
