import birdie
import gleeunit/should
import lexer/lexer
import parser/schema/document
import pprint
import simplifile

pub fn parse_schema_document_test() {
  simplifile.read("test.schema.graphql")
  |> should.be_ok
  |> lexer.lex
  |> should.be_ok
  |> document.parse_schema_document([])
  |> should.be_ok
  |> pprint.format
  |> birdie.snap(title: "test schema parsed")
}
