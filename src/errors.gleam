import internal/lexer/position
import internal/parser/node
import internal/schema/types

pub type LexError {
  InvalidCharacter(val: String, pos: position.Position)
  InvalidNumber(val: String, pos: position.Position)
  UnterminatedString(val: String, pos: position.Position)
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
  InvalidOperationType
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

pub type SchemaValidationError {
  MissingQueryType
  NameCollision(name: String)
  MissingType(name: String)
  InvalidRootOperationType
  InvalidArgument(error: ArgumentValidationError)
  InvalidConstValueUsage(error: ConstValueValidationError)
  InvalidScalarType
  InvalidObjectType
  InvalidInputType
  InvalidInterfaceType
  InvalidUnionType
  InvalidEnumType
  InvalidInterfaceImplementation(error: InterfaceImplementationValidationError)
  InvalidUnionMember(error: UnionMemberValidationError)
  InvalidDirective(error: DirectiveValidationError)
  InvalidInputField
  InvalidOutputField(error: OutputFieldValidationError)
}

pub type InterfaceImplementationValidationError {
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

pub type UnionMemberValidationError {
  UndefinedMember(name: String, member: String)
  NonObjectMember(name: String, member: String)
}

pub type ConstValueValidationError {
  InvalidEnumValue(value: String)
  NullValueForNonNullType
}

pub type ArgumentValidationError {
  UndefinedArgument(name: String)
}

pub type ScalarValidationError

pub type DirectiveValidationError {
  DuplicateNonRepeatable(directive_name: String)
  DirectiveNotSupportedAtLocation(
    directive_name: String,
    location: node.DirectiveLocation,
  )
  DirectiveNotDefined(directive_name: String)
}

pub type OutputFieldValidationError {
  UndefinedOutputFieldType(name: String)
  InvalidOutputFieldType(name: String)
}
