import gleam/dict
import gleam/option
import gleeunit/should
import internal/executable/operation/executable
import internal/executable/schema/executable as schema_executable
import internal/executable/schema/type_system
import internal/executable/types
import internal/lexer/lexer
import internal/parser/operation/document
import internal/parser/schema/document as schema_document
import simplifile

pub fn make_executable_schema_test() {
  let executable_schema =
    simplifile.read("test.schema.graphql")
    |> should.be_ok
    |> lexer.lex
    |> should.be_ok
    |> schema_document.parse_schema_document([])
    |> should.be_ok
    |> type_system.from_schema_doc
    |> should.be_ok
    |> schema_executable.from_types(option.None)
    |> should.be_ok

  let file =
    simplifile.read("test.operation.graphql")
    |> should.be_ok

  file
  |> lexer.lex
  |> should.be_ok
  |> document.parse_operations_document([])
  |> should.be_ok
  |> executable.make_executable(
    executable_schema,
    option.Some("GetUser"),
    dict.new()
      |> dict.insert(
        "userId",
        types.ExecutableConstScalar(types.ExecutableStringVal("id-123")),
      ),
  )
  |> should.be_ok
}
