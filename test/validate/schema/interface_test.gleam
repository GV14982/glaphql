import errors
import gleam/option
import gleam/result
import internal/executable/schema/executable
import internal/executable/schema/type_system
import internal/executable/types
import internal/lexer/lexer
import internal/parser/schema/document

pub fn validate_interface_implementations_test() {
  let schema =
    "
type Query {
  obj: Obj
}

interface Interface {
  a: String
}

type Obj implements Interface {
  a: String
  b: Int
}
    "
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  assert executable.from_types(ts, option.None) |> result.is_ok
}

pub fn incomplete_interface_implementation_test() {
  let schema =
    "
type Query {
  obj: Obj
}

interface Parent {
  c: Boolean
}

interface Interface implements Parent {
  a: String
  c: Boolean
}

type Obj implements Interface {
  a: String
  b: Int
}
    "
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  let assert Error(err) = executable.from_types(ts, option.None)
  assert err
    == errors.InvalidInterfaceImplementation(
      errors.IncompleteInterfaceImplementation("Obj"),
    )

  let schema =
    "
type Query {
  obj: Obj
}

interface Grandparent {
  d: Float
}

interface Parent implements Grandparent {
  c: Boolean
  d: Float
}

interface Interface implements Parent  {
  a: String
  c: Boolean
}

type Obj implements Interface & Parent {
  a: String
  b: Int
  c: Boolean
}
    "
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  let assert Error(err) = executable.from_types(ts, option.None)
  assert err
    == errors.InvalidInterfaceImplementation(
      errors.IncompleteInterfaceImplementation("Interface"),
    )
}

pub fn missing_fields_test() {
  let schema =
    "
type Query {
  obj: Obj
}

interface Interface {
  a: String
}

type Obj implements Interface {
  b: Int
}
    "
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  let assert Error(err) = executable.from_types(ts, option.None)
  assert err
    == errors.InvalidInterfaceImplementation(errors.MissingFields("Obj", ["a"]))
}

pub fn incorrect_fields_test() {
  let schema =
    "
type Query {
  obj: Obj
}

interface Interface {
  a: String
}

type Obj implements Interface {
  a: Boolean
  b: Int
}
    "
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  let assert Error(err) = executable.from_types(ts, option.None)
  assert err
    == errors.InvalidInterfaceImplementation(errors.IncorrectFieldType(
      name: "Obj",
      field: "a",
      expected_type: types.NamedType(types.ExecutableNamedType(
        name: "String",
        nullable: True,
      )),
      found_type: types.NamedType(types.ExecutableNamedType(
        name: "Boolean",
        nullable: True,
      )),
    ))
}
