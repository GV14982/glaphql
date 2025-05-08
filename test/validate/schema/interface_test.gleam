import errors
import gleam/option
import gleeunit/should
import lexer/lexer
import parser/schema/document
import schema/executable
import schema/type_system
import schema/types

pub fn validate_interface_implementations_test() -> Nil {
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

pub fn incomplete_interface_implementation_test() {
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
  |> lexer.lex
  |> should.be_ok
  |> document.parse_schema_document([])
  |> should.be_ok
  |> type_system.from_schema_doc
  |> should.be_ok
  |> executable.from_types(option.None)
  |> should.be_error
  |> should.equal(
    errors.InvalidInterfaceImplementation(
      errors.IncompleteInterfaceImplementation("Obj"),
    ),
  )

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
  |> lexer.lex
  |> should.be_ok
  |> document.parse_schema_document([])
  |> should.be_ok
  |> type_system.from_schema_doc
  |> should.be_ok
  |> executable.from_types(option.None)
  |> should.be_error
  |> should.equal(
    errors.InvalidInterfaceImplementation(
      errors.IncompleteInterfaceImplementation("Interface"),
    ),
  )
}

pub fn missing_fields_test() {
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
  |> lexer.lex
  |> should.be_ok
  |> document.parse_schema_document([])
  |> should.be_ok
  |> type_system.from_schema_doc
  |> should.be_ok
  |> executable.from_types(option.None)
  |> should.be_error
  |> should.equal(
    errors.InvalidInterfaceImplementation(errors.MissingFields("Obj", ["a"])),
  )
}

pub fn incorrect_fields_test() {
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
  |> lexer.lex
  |> should.be_ok
  |> document.parse_schema_document([])
  |> should.be_ok
  |> type_system.from_schema_doc
  |> should.be_ok
  |> executable.from_types(option.None)
  |> should.be_error
  |> should.equal(
    errors.InvalidInterfaceImplementation(errors.IncorrectFieldType(
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
    )),
  )
}
