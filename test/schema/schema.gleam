import birdie
import gleam/option
import gleeunit/should
import internal/executable/schema/executable
import internal/executable/schema/type_system
import internal/lexer/lexer
import internal/parser/schema/document
import pprint
import simplifile

pub fn make_executable_schema_test() {
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
  |> pprint.format
  |> birdie.snap(title: "test schema validated")
}
