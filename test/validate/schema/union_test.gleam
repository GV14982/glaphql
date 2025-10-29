import errors
import gleam/option
import gleam/result
import internal/executable/schema/executable
import internal/executable/schema/type_system
import internal/lexer/lexer
import internal/parser/schema/document

pub fn validate_union_members_test() {
  let schema =
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
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  assert executable.from_types(ts, option.None) |> result.is_ok
}

pub fn invalid_union_member() {
  let schema =
    "
type Query {
  obj: Obj
}

type A {
  a: String
}

union Obj = A | String
    "
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  let assert Error(err) = executable.from_types(ts, option.None)
  assert err
    == errors.InvalidUnionMember(errors.NonObjectMember(
      name: "Obj",
      member: "String",
    ))
}

pub fn missing_union_member() {
  let schema =
    "
type Query {
  obj: Obj
}

type A {
  a: String
}

union Obj = A | Missing
    "
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  let assert Error(err) = executable.from_types(ts, option.None)
  assert err
    == errors.InvalidUnionMember(errors.NonObjectMember(
      name: "Obj",
      member: "Missing",
    ))
}
