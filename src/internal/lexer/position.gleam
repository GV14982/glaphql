/// Represents a position in the source text (column and row).
pub type Position {
  Position(col: Int, row: Int)
}

/// Represents an offset as a tuple of start and end positions.
pub type Offset =
  #(Position, Position)

/// Creates a new Position at the start of the document (col: 1, row: 1).
pub fn new() {
  Position(col: 1, row: 1)
}

/// Increments the column of a Position by a given amount.
pub fn inc_col_by(pos: Position, by: Int) -> Position {
  let new_col = pos.col + by
  Position(..pos, col: new_col)
}

/// Increments the row of a Position by 1 and resets the column to 1.
pub fn inc_row(pos: Position) -> Position {
  Position(col: 1, row: pos.row + 1)
}
