import errors
import gleam/option
import gleam/result
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/const_value
import internal/parser/node

@internal
pub fn parse_optional(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(option.Option(node.ConstValueNode)),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.Equal, _), ..tokens] -> {
      use #(value, tokens) <- result.try(const_value.parse_const_value(tokens))
      Ok(#(option.Some(value), tokens))
    }
    _ -> Ok(#(option.None, tokens))
  }
}
