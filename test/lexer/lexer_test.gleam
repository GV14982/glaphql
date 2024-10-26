import birdie
import errors
import gleam/list
import gleam/result
import gleam/string
import gleeunit/should
import lexer/lexer
import lexer/position
import lexer/token_kind
import pprint
import simplifile

pub fn get_next_token_test() {
  let special_chars = [
    #("!", token_kind.Bang),
    #("?", token_kind.Question),
    #("$", token_kind.Dollar),
    #("&", token_kind.Amp),
    #(":", token_kind.Colon),
    #("=", token_kind.Equal),
    #("@", token_kind.At),
    #("|", token_kind.Pipe),
    #("(", token_kind.OpenParen),
    #(")", token_kind.CloseParen),
    #("[", token_kind.OpenBracket),
    #("]", token_kind.CloseBracket),
    #("{", token_kind.OpenBrace),
    #("}", token_kind.CloseBrace),
  ]

  let start = position.new()
  let end = start |> position.inc_col_by(1)
  special_chars
  |> list.each(fn(c) {
    let #(input, output) = c
    let lexed = lexer.Lexer(input, start) |> lexer.get_next_token
    lexed
    |> should.be_ok
    |> should.equal(#(
      #(output, #(start, start)),
      lexer.Lexer(input: "", pos: end),
    ))
  })

  let spread = "..."
  let lexed = lexer.Lexer(spread, start) |> lexer.get_next_token
  lexed
  |> should.be_ok
  |> should.equal(#(
    #(token_kind.Spread, #(start, start |> position.inc_col_by(2))),
    lexer.Lexer(input: "", pos: end |> position.inc_col_by(2)),
  ))

  let comment = "# This is a comment"
  let lexed = lexer.Lexer(comment, start) |> lexer.get_next_token
  lexed
  |> should.be_ok
  |> should.equal(#(
    #(token_kind.Comment(" This is a comment"), #(
      start,
      start |> position.inc_col_by(comment |> string.length),
    )),
    lexer.Lexer(
      input: "",
      pos: end |> position.inc_col_by(comment |> string.length),
    ),
  ))

  let str = "\"This is a string\""
  let length = { str |> string.length } - 2
  let lexed = lexer.Lexer(str, start) |> lexer.get_next_token
  lexed
  |> should.be_ok
  |> should.equal(#(
    #(token_kind.String("This is a string"), #(
      start,
      start |> position.inc_col_by(length + 1),
    )),
    lexer.Lexer(input: "", pos: end |> position.inc_col_by(length + 1)),
  ))
  let str =
    "\"\"\"
This is a block string
\"\"\""
  let lexed = lexer.Lexer(str, start) |> lexer.get_next_token
  lexed
  |> should.be_ok
  |> should.equal(#(
    #(token_kind.String("\nThis is a block string\n"), #(
      start,
      start |> position.inc_row |> position.inc_row |> position.inc_col_by(3),
    )),
    lexer.Lexer(
      input: "",
      pos: end |> position.inc_row |> position.inc_row |> position.inc_col_by(4),
    ),
  ))

  let name = "Name"
  let lexed = lexer.Lexer(name, start) |> lexer.get_next_token
  lexed
  |> should.be_ok
  |> should.equal(#(
    #(token_kind.Name("Name"), #(
      start,
      start |> position.inc_col_by({ name |> string.length } - 1),
    )),
    lexer.Lexer(
      input: "",
      pos: end |> position.inc_col_by({ name |> string.length } - 1),
    ),
  ))

  let int = "100"
  let lexed = lexer.Lexer(int, start) |> lexer.get_next_token
  lexed
  |> should.be_ok
  |> should.equal(#(
    #(token_kind.Int("100"), #(
      start,
      start |> position.inc_col_by({ int |> string.length } - 1),
    )),
    lexer.Lexer(
      input: "",
      pos: end |> position.inc_col_by({ int |> string.length } - 1),
    ),
  ))

  let float = "10.0"
  let lexed = lexer.Lexer(float, start) |> lexer.get_next_token
  lexed
  |> should.be_ok
  |> should.equal(#(
    #(token_kind.Float("10.0"), #(
      start,
      start |> position.inc_col_by({ float |> string.length } - 1),
    )),
    lexer.Lexer(
      input: "",
      pos: end |> position.inc_col_by({ float |> string.length } - 1),
    ),
  ))
}

pub fn schema_lex_test() {
  use schema <- result.try(
    simplifile.read("test.schema.graphql")
    |> result.map(string.trim)
    |> result.map_error(fn(_e) { Nil }),
  )
  let lexed = lexer.lex(schema) |> result.map_error(errors.LexError)
  should.be_ok(lexed)
  lexed
  |> pprint.format
  |> birdie.snap(title: "test schema lexed")
  Ok(Nil)
}

pub fn operations_lex_test() {
  use operations <- result.try(
    simplifile.read("test.operation.graphql")
    |> result.map(string.trim)
    |> result.map_error(fn(_e) { Nil }),
  )
  let lexed = lexer.lex(operations) |> result.map_error(errors.LexError)
  should.be_ok(lexed)
  lexed
  |> pprint.format
  |> birdie.snap(title: "test operations lexed")
  Ok(Nil)
}
