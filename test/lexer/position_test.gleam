import gleeunit/should
import lexer/position

pub fn new_position_test() {
  let pos = position.new()
  should.equal(pos.col, 1)
  should.equal(pos.row, 1)
}

pub fn inc_col_by_test() {
  let pos = position.new() |> position.inc_col_by(1)
  should.equal(pos.col, 2)
  should.equal(pos.row, 1)

  let pos = position.new() |> position.inc_col_by(5)
  should.equal(pos.col, 6)
  should.equal(pos.row, 1)
}

pub fn inc_row_test() {
  let pos = position.new() |> position.inc_row
  should.equal(pos.col, 1)
  should.equal(pos.row, 2)

  // Make sure that the col always gets reset to 1 when increasing the row
  let pos = position.new() |> position.inc_col_by(5) |> position.inc_row
  should.equal(pos.col, 1)
  should.equal(pos.row, 2)
}
