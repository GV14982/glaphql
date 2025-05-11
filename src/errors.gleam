/// This module defines all error types used throughout the GraphQL implementation.
/// Error types are grouped by category and follow consistent naming patterns.

import internal/lexer/position
import internal/parser/node
import internal/schema/types

/// Represents errors that can occur during lexical analysis of GraphQL documents
pub type LexError {
  /// An invalid character was encountered during lexing
  InvalidCharacter(value: String, pos: position.Position)
  /// An invalid number format was encountered
  InvalidNumber(value: String, pos: position.Position)
  /// A string was not properly terminated
  UnterminatedString(value: String, pos: position.Position)
}

/// Represents errors that can occur during parsing of GraphQL documents
pub type ParseError {
  /// A lexical error occurred during parsing
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

/// Maps a lexical error to a parse error
pub fn map_lex_to_parse_error(err: LexError) -> ParseError {
  LexError(err)
}

/// Represents errors that can occur during schema validation
pub type SchemaError {
  /// The schema is missing a required query root type
  MissingQueryType
  /// A name collision was detected in the schema
  NameCollision(name: String)
  /// A referenced type is missing from the schema
  MissingType(name: String)
  /// A root operation type is invalid
  InvalidRootOperationType
  /// An argument failed validation
  InvalidArgument(error: ArgumentError)
  /// A constant value was used incorrectly
  InvalidConstValueUsage(error: ConstValueError)
  /// A scalar type is invalid
  InvalidScalarType
  /// An object type is invalid
  InvalidObjectType
  /// An input type is invalid
  InvalidInputType
  /// An interface type is invalid
  InvalidInterfaceType
  /// A union type is invalid
  InvalidUnionType
  /// An enum type is invalid
  InvalidEnumType
  /// An interface implementation is invalid
  InvalidInterfaceImplementation(error: InterfaceImplementationError)
  /// A union member is invalid
  InvalidUnionMember(error: UnionMemberError)
  /// A directive is invalid
  InvalidDirective(error: DirectiveError)
  /// An input field is invalid
  InvalidInputField(error: FieldError)
  /// An output field is invalid
  InvalidOutputField(error: FieldError)
}

/// Represents errors related to interface implementation validation
pub type InterfaceImplementationError {
  /// Interface list contains duplicates
  NonUniqueInterfaceList(name: String)
  /// Referenced interface is not defined
  UndefinedInterface(name: String)
  /// Type implements something that is not an interface
  ImplementsNonInterface(name: String)
  /// Interface references cause a cycle
  CyclicInterfaceReference(name: String)
  /// Interface implementation is incomplete
  IncompleteInterfaceImplementation(name: String)
  /// Interface implementation is missing required fields
  MissingFields(name: String, fields: List(String))
  /// Field has incorrect type compared to interface
  IncorrectFieldType(
    name: String,
    field: String,
    expected_type: types.ExecutableType,
    found_type: types.ExecutableType,
  )
}

/// Represents errors related to union member validation
pub type UnionMemberError {
  /// Union member is not defined
  UndefinedMember(name: String, member: String)
  /// Union member is not an object type
  NonObjectMember(name: String, member: String)
}

/// Represents errors related to constant value validation
pub type ConstValueError {
  /// Enum value is invalid
  InvalidEnumValue(value: String)
  /// Null value is used with a non-null type
  NullValueForNonNullType
}

/// Represents errors related to argument validation
pub type ArgumentError {
  /// Argument is not defined
  UndefinedArgument(name: String)
}

/// Represents errors related to scalar validation
pub type ScalarError

/// Represents errors related to directive validation
pub type DirectiveError {
  /// A non-repeatable directive appears multiple times
  DuplicateNonRepeatable(directive_name: String)
  /// Directive is used at a location where it's not supported
  DirectiveNotSupportedAtLocation(
    directive_name: String,
    location: node.DirectiveLocation,
  )
  /// Referenced directive is not defined
  DirectiveNotDefined(directive_name: String)
}

/// Represents errors related to field validation
pub type FieldError {
  /// Field type is not defined
  UndefinedFieldType(name: String)
  /// Field has an invalid type
  InvalidFieldType(name: String)
}
