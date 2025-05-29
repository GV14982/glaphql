import gleam/list
import gleeunit/should
import internal/lexer/predicates

pub fn is_ignored_test() -> Nil {
  [" ", "\t", "\n", "\r", ",", "#"]
  |> list.each(fn(val) { predicates.is_ignored(val) |> should.be_true })
  ["foo", "bar", "type"]
  |> list.each(fn(val) { predicates.is_ignored(val) |> should.be_false })
}

pub fn is_name_test() -> Nil {
  ["a", "Z", "m", "_", "B", "x", "2", "n"]
  |> list.each(fn(char) {predicates.is_name(char) |> should.be_true})
  [ "-", "$", "@", " ", "\n", "#"]
  |> list.each(fn(char) {predicates.is_name(char) |> should.be_false})
}


pub fn is_name_start_test() -> Nil {
  ["a", "Z", "m", "_", "B", "x", "Y", "n"]
  |> list.each(fn(char) {predicates.is_name_start(char) |> should.be_true})
  ["1", "9", "-", "$", "@", " ", "\n", "", "#", "."]
  |> list.each(fn(char) {predicates.is_name_start(char) |> should.be_false})
}


pub fn is_alphanumeric_test() -> Nil {
  ["a","c","0","2","z"]
  |> list.each(fn(char) {predicates.is_alphanumeric(char) |> should.be_true })
  ["#","(","!","~","-"]
  |> list.each(fn(char) {predicates.is_alphanumeric(char) |> should.be_false })
}

pub fn is_digit_test() -> Nil {
  ["1","2","3","0","4"]
  |> list.each(fn(char) {predicates.is_digit(char) |> should.be_true })
  ["_", "z", "@", " ", "\n"]
  |> list.each(fn(char) {predicates.is_digit(char) |> should.be_false })
}

pub fn is_non_zero_digit_test() -> Nil {
  ["1","2","3","2","4"]
  |> list.each(fn(char) {predicates.is_non_zero_digit(char) |> should.be_true })
  ["_", "z", "@", "0", "\n"]
  |> list.each(fn(char) {predicates.is_non_zero_digit(char) |> should.be_false })
}

pub fn is_alpha_test() -> Nil {
  ["a","c","q","e","z"]
  |> list.each(fn(char) {predicates.is_alpha(char) |> should.be_true })
  ["#","(","!","~","-"]
  |> list.each(fn(char) {predicates.is_alpha(char) |> should.be_false })
}


pub fn is_upper_test() -> Nil {
  ["Z","C","Q","E","X"]
  |> list.each(fn(char) {predicates.is_upper(char) |> should.be_true })
  ["a","c","q","e","z"]
  |> list.each(fn(char) {predicates.is_upper(char) |> should.be_false })
}

pub fn is_lower_test() -> Nil {
  ["a","c","q","e","z"]
  |> list.each(fn(char) {predicates.is_lower(char) |> should.be_true })
  ["P","C","Q","Z","X"]
  |> list.each(fn(char) {predicates.is_lower(char) |> should.be_false })
}