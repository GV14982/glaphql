import errors
import gleam/option
import gleeunit/should
import internal/lexer/lexer
import internal/parser/node
import internal/parser/schema/document
import internal/schema/executable
import internal/schema/type_system

pub fn directive_validation_test() -> Nil {
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
  |> lexer.lex
  |> should.be_ok
  |> document.parse_schema_document([])
  |> should.be_ok
  |> type_system.from_schema_doc
  |> should.be_ok
  |> executable.from_types(option.None)
  |> should.be_ok
  Nil
}

pub fn missing_directive_def_test() -> Nil {
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
  |> lexer.lex
  |> should.be_ok
  |> document.parse_schema_document([])
  |> should.be_ok
  |> type_system.from_schema_doc
  |> should.be_ok
  |> executable.from_types(option.None)
  |> should.be_error
  |> should.equal(
    errors.InvalidDirective(errors.DirectiveNotDefined("onFieldDef")),
  )
}

pub fn incorrect_directive_location_test() -> Nil {
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
  |> lexer.lex
  |> should.be_ok
  |> document.parse_schema_document([])
  |> should.be_ok
  |> type_system.from_schema_doc
  |> should.be_ok
  |> executable.from_types(option.None)
  |> should.be_error
  |> should.equal(
    errors.InvalidDirective(errors.DirectiveNotSupportedAtLocation(
      "onFieldDef",
      node.TypeSystemDirectiveLocation(node.FieldDefinitionDirective),
    )),
  )
}

pub fn duplicate_non_repeatable_test() -> Nil {
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
  |> lexer.lex
  |> should.be_ok
  |> document.parse_schema_document([])
  |> should.be_ok
  |> type_system.from_schema_doc
  |> should.be_ok
  |> executable.from_types(option.None)
  |> should.be_error
  |> should.equal(
    errors.InvalidDirective(errors.DuplicateNonRepeatable("onObject")),
  )
}
