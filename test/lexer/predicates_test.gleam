import gleam/int
import gleam/iterator
import gleam/list
import gleeunit/should
import lexer/predicates

const upper = [
  "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
  "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
]

const lower = [
  "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p",
  "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
]

pub fn is_ignored_test() -> Nil {
  let space = predicates.is_ignored(" ")
  should.be_true(space)
  let tab = predicates.is_ignored("\t")
  should.be_true(tab)
  let newline = predicates.is_ignored("\n")
  should.be_true(newline)
  let carriage_return = predicates.is_ignored("\r")
  should.be_true(carriage_return)
  let comma = predicates.is_ignored(",")
  should.be_true(comma)
  let hash = predicates.is_ignored("#")
  should.be_true(hash)
  let non_ignored = predicates.is_ignored("hi")
  should.be_false(non_ignored)
}

fn get_digit_list() -> List(String) {
  iterator.range(from: 0, to: 9)
  |> iterator.map(with: int.to_string)
  |> iterator.to_list
}

pub fn is_lower_test() -> Nil {
  list.each(lower, fn(element) {
    predicates.is_lower(element) |> should.be_true
  })
  list.each(upper, fn(element) {
    predicates.is_lower(element) |> should.be_false
  })
}

pub fn is_upper_test() -> Nil {
  list.each(upper, fn(element) {
    predicates.is_upper(element) |> should.be_true
  })
  list.each(lower, fn(element) {
    predicates.is_upper(element) |> should.be_false
  })
}

pub fn is_digit_test() {
  get_digit_list()
  |> list.each(fn(element) { predicates.is_digit(element) |> should.be_true })

  list.concat([upper, lower])
  |> list.each(fn(element) { predicates.is_digit(element) |> should.be_false })
}

pub fn is_non_zero_digit_test() {
  get_digit_list()
  |> list.drop(1)
  |> list.each(fn(element) {
    predicates.is_non_zero_digit(element) |> should.be_true
  })

  predicates.is_non_zero_digit("0") |> should.be_false

  list.concat([upper, lower])
  |> list.each(fn(element) { predicates.is_digit(element) |> should.be_false })
}

pub fn is_alpha_test() {
  list.concat([upper, lower])
  |> list.each(fn(element) { predicates.is_alpha(element) |> should.be_true })

  get_digit_list()
  |> list.each(fn(element) { predicates.is_alpha(element) |> should.be_false })
}

pub fn is_alphanumeric_test() {
  list.concat([upper, lower, get_digit_list()])
  |> list.each(fn(element) {
    predicates.is_alphanumeric(element) |> should.be_true
  })
  predicates.is_alphanumeric("!") |> should.be_false
}

pub fn is_name_start_test() {
  list.concat([upper, lower, ["_"]])
  |> list.each(fn(element) {
    predicates.is_name_start(element) |> should.be_true
  })

  get_digit_list()
  |> list.each(fn(element) {
    predicates.is_name_start(element) |> should.be_false
  })

  predicates.is_name_start("!") |> should.be_false
}

pub fn is_name_test() {
  list.concat([upper, lower, get_digit_list(), ["_"]])
  |> list.each(fn(element) { predicates.is_name(element) |> should.be_true })

  predicates.is_name("!") |> should.be_false
}
