import gleam/list
import internal/lexer/predicates

pub fn is_ignored_test() {
  [" ", "\t", "\n", "\r", ",", "#"]
  |> list.each(fn(val) {
    assert predicates.is_ignored(val)
  })
  ["foo", "bar", "type"]
  |> list.each(fn(val) {
    assert !predicates.is_ignored(val)
  })
}

pub fn is_name_test() {
  ["a", "Z", "m", "_", "B", "x", "2", "n"]
  |> list.each(fn(char) {
    assert predicates.is_name(char)
  })
  ["-", "$", "@", " ", "\n", "#"]
  |> list.each(fn(char) {
    assert !predicates.is_name(char)
  })
}

pub fn is_name_start_test() {
  ["a", "Z", "m", "_", "B", "x", "Y", "n"]
  |> list.each(fn(char) {
    assert predicates.is_name_start(char)
  })
  ["1", "9", "-", "$", "@", " ", "\n", "", "#", "."]
  |> list.each(fn(char) {
    assert !predicates.is_name_start(char)
  })
}

pub fn is_alphanumeric_test() {
  ["a", "c", "0", "2", "z"]
  |> list.each(fn(char) {
    assert predicates.is_alphanumeric(char)
  })
  ["#", "(", "!", "~", "-"]
  |> list.each(fn(char) {
    assert !predicates.is_alphanumeric(char)
  })
}

pub fn is_digit_test() {
  ["1", "2", "3", "0", "4"]
  |> list.each(fn(char) {
    assert predicates.is_digit(char)
  })
  ["_", "z", "@", " ", "\n"]
  |> list.each(fn(char) {
    assert !predicates.is_digit(char)
  })
}

pub fn is_non_zero_digit_test() {
  ["1", "2", "3", "2", "4"]
  |> list.each(fn(char) {
    assert predicates.is_non_zero_digit(char)
  })
  ["_", "z", "@", "0", "\n"]
  |> list.each(fn(char) {
    assert !predicates.is_non_zero_digit(char)
  })
}

pub fn is_alpha_test() {
  ["a", "c", "q", "e", "z"]
  |> list.each(fn(char) {
    assert predicates.is_alpha(char)
  })
  ["#", "(", "!", "~", "-"]
  |> list.each(fn(char) {
    assert !predicates.is_alpha(char)
  })
}

pub fn is_upper_test() {
  ["Z", "C", "Q", "E", "X"]
  |> list.each(fn(char) {
    assert predicates.is_upper(char)
  })
  ["a", "c", "q", "e", "z"]
  |> list.each(fn(char) {
    assert !predicates.is_upper(char)
  })
}

pub fn is_lower_test() {
  ["a", "c", "q", "e", "z"]
  |> list.each(fn(char) {
    assert predicates.is_lower(char)
  })
  ["P", "C", "Q", "Z", "X"]
  |> list.each(fn(char) {
    assert !predicates.is_lower(char)
  })
}
