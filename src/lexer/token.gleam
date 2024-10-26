import lexer/position.{type Offset}
import lexer/token_kind.{type TokenKind}

pub type Token =
  #(TokenKind, Offset)
