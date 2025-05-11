import errors
import gleam/option
import gleeunit/should
import internal/lexer/lexer
import internal/parser/schema/document
import internal/schema/executable
import internal/schema/type_system
import internal/schema/types

pub fn validate_union_members_test() {
  "
type Query {
  obj: Obj
}

type A {
  a: String
}

type B {
  b: String
}

union Obj = A | B
    "
  |> lexer.lex
  |> should.be_ok
  |> document.parse_schema_document([])
  |> should.be_ok
  |> type_system.from_schema_doc
  |> should.be_ok
  |> executable.from_types(option.None)
  |> should.be_ok
}

pub fn invalid_union_member() {
  "
type Query {
  obj: Obj
}

type A {
  a: String
}

union Obj = A | String
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
    errors.InvalidUnionMember(errors.NonObjectMember(
      name: "Obj",
      member: "String",
    )),
  )
}

pub fn missing_union_member() {
  "
type Query {
  obj: Obj
}

type A {
  a: String
}

union Obj = A | Missing
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
    errors.InvalidUnionMember(errors.NonObjectMember(
      name: "Obj",
      member: "Missing",
    )),
  )
}
