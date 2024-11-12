import errors
import gleam/list
import gleam/result
import gleam/string
import lexer/position
import lexer/predicates
import lexer/token
import lexer/token_kind

@internal
pub type Lexer {
  Lexer(input: String, pos: position.Position)
}

@internal
pub type LexResult =
  Result(List(token.Token), errors.LexError)

@internal
pub type TokenResult =
  Result(#(token.Token, Lexer), errors.LexError)

type AccumulatedVal(a) =
  #(String, a, position.Position)

@internal
pub type NumberType {
  Integer
  Float
}

@internal
pub fn lex(input: String) -> LexResult {
  let init_lexer = Lexer(input, position.new())
  lex_until_error(init_lexer, [])
}

@internal
pub fn lex_until_error(lexer: Lexer, tokens: List(token.Token)) -> LexResult {
  let token_result = get_next_token(lexer)
  case token_result {
    Ok(#(token, lexer)) ->
      case token.0 {
        token_kind.EOF -> Ok([token, ..tokens] |> list.reverse)
        _ -> lex_until_error(lexer, [token, ..tokens])
      }
    Error(err) -> Error(err)
  }
}

fn result_with_token(token: token.Token, lexer: Lexer) -> TokenResult {
  Ok(#(token, lexer))
}

@internal
pub fn lookahead(lexer: Lexer) -> TokenResult {
  use #(token, _lexer) <- result.try(get_next_token(lexer))
  Ok(#(token, lexer))
}

@internal
pub fn get_next_token(lexer: Lexer) -> TokenResult {
  case lexer.input {
    " " <> tail | "\t" <> tail | "," <> tail ->
      get_next_token(Lexer(tail, position.inc_col_by(lexer.pos, 1)))
    "\n" <> tail | "\r" <> tail | "\r\n" <> tail ->
      get_next_token(Lexer(tail, position.inc_row(lexer.pos)))
    "#" <> tail -> {
      let #(rest, comment, pos) =
        consume_comment(tail, "", position.inc_col_by(lexer.pos, 1))
      result_with_token(
        #(token_kind.Comment(comment), #(lexer.pos, pos)),
        Lexer(rest, position.inc_col_by(pos, 1)),
      )
    }
    "!" <> tail ->
      result_with_token(
        #(token_kind.Bang, #(lexer.pos, lexer.pos)),
        Lexer(tail, position.inc_col_by(lexer.pos, 1)),
      )
    "?" <> tail ->
      result_with_token(
        #(token_kind.Question, #(lexer.pos, lexer.pos)),
        Lexer(tail, position.inc_col_by(lexer.pos, 1)),
      )
    "$" <> tail ->
      result_with_token(
        #(token_kind.Dollar, #(lexer.pos, lexer.pos)),
        Lexer(tail, position.inc_col_by(lexer.pos, 1)),
      )
    "&" <> tail ->
      result_with_token(
        #(token_kind.Amp, #(lexer.pos, lexer.pos)),
        Lexer(tail, position.inc_col_by(lexer.pos, 1)),
      )
    ":" <> tail ->
      result_with_token(
        #(token_kind.Colon, #(lexer.pos, lexer.pos)),
        Lexer(tail, position.inc_col_by(lexer.pos, 1)),
      )
    "=" <> tail ->
      result_with_token(
        #(token_kind.Equal, #(lexer.pos, lexer.pos)),
        Lexer(tail, position.inc_col_by(lexer.pos, 1)),
      )
    "@" <> tail ->
      result_with_token(
        #(token_kind.At, #(lexer.pos, lexer.pos)),
        Lexer(tail, position.inc_col_by(lexer.pos, 1)),
      )
    "|" <> tail ->
      result_with_token(
        #(token_kind.Pipe, #(lexer.pos, lexer.pos)),
        Lexer(tail, position.inc_col_by(lexer.pos, 1)),
      )
    "(" <> tail ->
      result_with_token(
        #(token_kind.OpenParen, #(lexer.pos, lexer.pos)),
        Lexer(tail, position.inc_col_by(lexer.pos, 1)),
      )
    ")" <> tail ->
      result_with_token(
        #(token_kind.CloseParen, #(lexer.pos, lexer.pos)),
        Lexer(tail, position.inc_col_by(lexer.pos, 1)),
      )
    "[" <> tail ->
      result_with_token(
        #(token_kind.OpenBracket, #(lexer.pos, lexer.pos)),
        Lexer(tail, position.inc_col_by(lexer.pos, 1)),
      )
    "]" <> tail ->
      result_with_token(
        #(token_kind.CloseBracket, #(lexer.pos, lexer.pos)),
        Lexer(tail, position.inc_col_by(lexer.pos, 1)),
      )
    "{" <> tail ->
      result_with_token(
        #(token_kind.OpenBrace, #(lexer.pos, lexer.pos)),
        Lexer(tail, position.inc_col_by(lexer.pos, 1)),
      )
    "}" <> tail ->
      result_with_token(
        #(token_kind.CloseBrace, #(lexer.pos, lexer.pos)),
        Lexer(tail, position.inc_col_by(lexer.pos, 1)),
      )
    "..." <> tail ->
      result_with_token(
        #(token_kind.Spread, #(lexer.pos, position.inc_col_by(lexer.pos, 2))),
        Lexer(tail, position.inc_col_by(lexer.pos, 3)),
      )
    "\"\"\"" <> tail -> {
      use #(rest, val, end) <- result.try(consume_block_string(
        tail,
        "",
        lexer.pos,
      ))
      result_with_token(
        #(token_kind.String(val), #(lexer.pos, end)),
        Lexer(rest, position.inc_col_by(end, 1)),
      )
    }
    "\"" <> tail -> {
      use #(rest, val, end) <- result.try(consume_string(tail, "", lexer.pos))
      result_with_token(
        #(token_kind.String(val), #(lexer.pos, end)),
        Lexer(rest, position.inc_col_by(end, 1)),
      )
    }
    "" -> {
      result_with_token(#(token_kind.EOF, #(lexer.pos, lexer.pos)), lexer)
    }
    _ -> handle_name_or_number(lexer)
  }
}

@internal
pub fn handle_name_or_number(lexer: Lexer) -> TokenResult {
  use #(head, tail) <- result.try(
    string.pop_grapheme(lexer.input)
    |> result.try_recover(fn(_) { Ok(#("", "")) }),
  )
  let is_number_start = predicates.is_non_zero_digit(head) || head == "-"
  case is_number_start {
    True -> {
      use #(rest, #(val, number_type), end) <- result.try(consume_number(
        tail,
        head,
        lexer.pos,
        Integer,
      ))
      result_with_token(
        #(number_type_to_token_kind(number_type, val), #(lexer.pos, end)),
        Lexer(rest, position.inc_col_by(end, 1)),
      )
    }
    False -> {
      let is_name_start = predicates.is_alpha(head) || head == "_"
      case is_name_start {
        True -> {
          use #(rest, val, end) <- result.try(consume_name(
            tail,
            head,
            lexer.pos,
          ))
          result_with_token(
            #(token_kind.Name(val), #(lexer.pos, end)),
            Lexer(rest, position.inc_col_by(end, 1)),
          )
        }
        False -> {
          Error(errors.InvalidCharacter(head, lexer.pos))
        }
      }
    }
  }
}

@internal
pub fn consume_comment(
  input: String,
  comment: String,
  pos: position.Position,
) -> AccumulatedVal(String) {
  case input {
    "\n" <> rest | "\r" <> rest | "\r\n" <> rest -> #(
      rest,
      comment,
      position.inc_row(pos),
    )
    _ ->
      case string.pop_grapheme(input) {
        Ok(#(head, tail)) ->
          consume_comment(tail, comment <> head, position.inc_col_by(pos, 1))
        Error(_) -> #(input, comment, pos)
      }
  }
}

@internal
pub fn consume_name(
  input: String,
  val: String,
  pos: position.Position,
) -> Result(AccumulatedVal(String), errors.LexError) {
  case input {
    _ ->
      case string.pop_grapheme(input) {
        Ok(#(head, tail)) -> {
          let is_name_continue = predicates.is_alphanumeric(head) || head == "_"
          case is_name_continue {
            True -> consume_name(tail, val <> head, position.inc_col_by(pos, 1))
            False -> Ok(#(input, val, pos))
          }
        }
        Error(_) -> Ok(#(input, val, pos))
      }
  }
}

@internal
pub fn consume_string(
  input: String,
  val: String,
  pos: position.Position,
) -> Result(AccumulatedVal(String), errors.LexError) {
  case input {
    "\"" <> tail -> Ok(#(tail, val, position.inc_col_by(pos, 1)))
    "\n" <> _tail | "\r" <> _tail | "\r\n" <> _tail ->
      Error(errors.UnterminatedString(val, pos))
    _ ->
      case string.pop_grapheme(input) {
        Ok(#(head, tail)) ->
          consume_string(tail, val <> head, position.inc_col_by(pos, 1))
        Error(_) -> Error(errors.UnterminatedString(val, pos))
      }
  }
}

@internal
pub fn consume_block_string(
  input: String,
  val: String,
  pos: position.Position,
) -> Result(AccumulatedVal(String), errors.LexError) {
  case input {
    "\"\"\"" <> tail -> Ok(#(tail, val, position.inc_col_by(pos, 3)))
    "\n" <> tail ->
      consume_block_string(tail, val <> "\n", position.inc_row(pos))
    "\r" <> tail ->
      consume_block_string(tail, val <> "\r", position.inc_row(pos))
    "\r\n" <> tail ->
      consume_block_string(tail, val <> "\r\n", position.inc_row(pos))
    _ ->
      case string.pop_grapheme(input) {
        Ok(#(head, tail)) ->
          consume_block_string(tail, val <> head, position.inc_col_by(pos, 1))
        Error(_) -> Error(errors.UnterminatedString(val, pos))
      }
  }
}

@internal
pub fn consume_number(
  input: String,
  val: String,
  pos: position.Position,
  number_type: NumberType,
) -> Result(AccumulatedVal(#(String, NumberType)), errors.LexError) {
  case string.pop_grapheme(input) {
    Ok(#(head, tail)) -> {
      case head {
        "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ->
          consume_number(
            tail,
            val <> head,
            position.inc_col_by(pos, 1),
            number_type,
          )
        "." | "e" ->
          consume_number(tail, val <> head, position.inc_col_by(pos, 1), Float)
        _ -> {
          let is_name_start = predicates.is_name_start(head)
          case is_name_start {
            True -> Error(errors.InvalidNumber(val <> head, pos))
            False -> Ok(#(input, #(val, number_type), pos))
          }
        }
      }
    }
    Error(_) -> Ok(#(input, #(val, number_type), pos))
  }
}

@internal
pub fn number_type_to_token_kind(
  number_type: NumberType,
  val: String,
) -> token_kind.TokenKind {
  case number_type {
    Integer -> token_kind.Int(val)
    Float -> token_kind.Float(val)
  }
}
