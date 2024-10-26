import lexer/position.{type Position}

pub type LexError {
  InvalidCharacter(val: String, pos: Position)
  InvalidNumber(val: String, pos: Position)
  UnterminatedString(val: String, pos: Position)
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
