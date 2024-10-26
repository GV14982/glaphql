pub type Position {
  Position(col: Int, row: Int)
}

pub type Offset =
  #(Position, Position)

pub fn new() {
  Position(col: 1, row: 1)
}

pub fn inc_col_by(pos: Position, by: Int) -> Position {
  let new_col = pos.col + by
  Position(..pos, col: new_col)
}

pub fn inc_row(pos: Position) -> Position {
  Position(col: 1, row: pos.row + 1)
}
