import internal/lexer/position
import internal/lexer/token_kind

pub type Token =
  #(token_kind.TokenKind, position.Offset)
