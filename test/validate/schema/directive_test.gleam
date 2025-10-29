import errors
import gleam/option
import gleam/result
import internal/executable/schema/executable
import internal/executable/schema/type_system
import internal/lexer/lexer
import internal/parser/node
import internal/parser/schema/document

pub fn directive_validation_test() {
  let schema =
    "
directive @onObject(arg1: String) on OBJECT
directive @onFieldDef(arg2: Int!) on FIELD_DEFINITION
type Query {
  obj: Obj
}

type Obj @onObject {
  a: String @onFieldDef(arg2: 69)
  obj: AnotherOne
}

type AnotherOne @onObject(arg1: \"Nice\") {
  b: Int!
}
    "
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  let assert True = executable.from_types(ts, option.None) |> result.is_ok
}

pub fn missing_directive_def_test() {
  let schema =
    "
directive @onObject(arg1: String) on OBJECT
type Query {
  obj: Obj
}

type Obj @onObject {
  a: String @onFieldDef(arg2: 69)
  obj: AnotherOne
}

type AnotherOne @onObject(arg1: \"Nice\") {
  b: Int!
}
    "
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  let assert Error(err) = executable.from_types(ts, option.None)
  assert err
    == errors.InvalidDirective(errors.DirectiveNotDefined("onFieldDef"))
}

pub fn incorrect_directive_location_test() {
  let schema =
    "
directive @onObject(arg1: String) on OBJECT
directive @onFieldDef(arg2: Int!) on FIELD
type Query {
  obj: Obj
}

type Obj @onObject {
  a: String @onFieldDef(arg2: 69)
  obj: AnotherOne
}

type AnotherOne @onObject(arg1: \"Nice\") {
  b: Int!
}
    "
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  let assert Error(err) = executable.from_types(ts, option.None)
  assert err
    == errors.InvalidDirective(errors.DirectiveNotSupportedAtLocation(
      "onFieldDef",
      node.TypeSystemDirectiveLocation(node.FieldDefinitionDirective),
    ))
}

pub fn duplicate_non_repeatable_test() {
  let schema =
    "
directive @onObject(arg1: String) on OBJECT
directive @onFieldDef(arg2: Int!) on FIELD_DEFINITION
type Query {
  obj: Obj
}

type Obj @onObject @onObject {
  a: String @onFieldDef(arg2: 69)
  obj: AnotherOne
}

type AnotherOne @onObject(arg1: \"Nice\") {
  b: Int!
}
    "
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  let assert Error(err) = executable.from_types(ts, option.None)
  assert err
    == errors.InvalidDirective(errors.DuplicateNonRepeatable("onObject"))
}
