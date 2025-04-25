import birdie
import errors
import gleam/result
import gleeunit/should
import lexer/lexer
import pprint
import simplifile

pub fn schema_lex_test() {
  simplifile.read("test.schema.graphql")
  |> should.be_ok
  |> lexer.lex
  |> result.map_error(errors.LexError)
  |> should.be_ok
  |> pprint.format
  |> birdie.snap(title: "test schema lexed")
  |> Ok
}

pub fn operations_lex_test() {
  simplifile.read("test.operation.graphql")
  |> should.be_ok
  |> lexer.lex
  |> result.map_error(errors.LexError)
  |> should.be_ok
  |> pprint.format
  |> birdie.snap(title: "test operations lexed")
  |> Ok
}
