import gleam/option
import gleeunit/should
import lexer/lexer
import parser/schema/document
import schema/executable
import schema/type_system
import simplifile

pub fn make_executable_schema_test() {
  let t =
    simplifile.read("test.schema.graphql")
    |> should.be_ok
    |> lexer.lex
    |> should.be_ok
    |> document.parse_schema_document([])
    |> should.be_ok
    |> type_system.from_schema_doc
    |> should.be_ok
    |> executable.from_types(option.None)
    |> should.be_ok
  // |> pprint.debug
  // |> birdie.snap(title: "test schema parsed")
}
