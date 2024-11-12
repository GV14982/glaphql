import lexer/position
import lexer/token_kind

pub type Token =
  #(token_kind.TokenKind, position.Offset)
