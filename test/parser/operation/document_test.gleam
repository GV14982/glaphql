import birdie
import gleeunit/should
import lexer/lexer
import parser/operation/document
import pprint
import simplifile

pub fn parse_executable_document_test() {
  simplifile.read("test.operation.graphql")
  |> should.be_ok
  |> lexer.lex
  |> should.be_ok
  |> document.parse_operations_document([])
  |> should.be_ok
  |> pprint.format
  |> birdie.snap(title: "test operations parsed")
}
