import lexer/position
import parser/node

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
  InvalidInterfaceImplementation
  InvalidUnionMember
  InvalidDirective(error: DirectiveValidationError)
  InvalidInputField
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
