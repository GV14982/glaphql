import birdie
import errors
import gleam/result
import gleeunit/should
import internal/lexer/lexer
import internal/lexer/position
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

pub fn consume_comment_test() {
  let #(rest, comment, pos) =
    lexer.consume_comment(
      "this is a comment\nyes",
      "",
      position.Position(row: 1, col: 1),
    )
  rest
  |> should.equal("yes")
  comment
  |> should.equal("this is a comment")
  pos
  |> should.equal(position.Position(row: 1, col: 18))
}
