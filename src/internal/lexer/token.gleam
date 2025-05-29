import internal/lexer/position
import internal/lexer/token_kind

/// Represents a token in the GraphQL source, including its kind and position offset.
pub type Token =
  #(token_kind.TokenKind, position.Offset)
