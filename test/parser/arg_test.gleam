import gleam/result
import gleeunit/should
import lexer/lexer
import lexer/position
import parser/arg

pub fn parse_optional_args_test() {
  let input = "(a: \"Hi\", c: 3)" |> lexer.lex
  should.be_ok(input)
  use lexed <- result.map(input)
  let parsed = arg.parse_optional_args(lexed, position.new())
  should.be_ok(parsed)
}
