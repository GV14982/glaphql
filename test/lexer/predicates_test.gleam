import gleam/list
import gleeunit/should
import internal/lexer/predicates

pub fn is_ignored_test() -> Nil {
  [" ", "\t", "\n", "\r", ",", "#"]
  |> list.each(fn(val) { predicates.is_ignored(val) |> should.be_true })
  ["foo", "bar", "type"]
  |> list.each(fn(val) { predicates.is_ignored(val) |> should.be_false })
}
