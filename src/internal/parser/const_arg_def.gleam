import errors
import gleam/option
import gleam/result
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/const_value
import internal/parser/node
import internal/parser/util

@internal
pub fn parse_optional_const_arg_defs(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(
    #(option.Option(List(node.ConstArgumentNode)), position.Position),
  ),
  errors.ParseError,
) {
  util.parse_between_optional(
    token_kind.OpenParen,
    token_kind.CloseParen,
    tokens,
    parse_const_arg_def,
  )
}

fn parse_const_arg_def(
  tokens: List(token.Token),
) -> Result(node.NodeWithTokenList(node.ConstArgumentNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(name), start), #(token_kind.Colon, _), ..tokens] -> {
      use #(value, tokens) <- result.try(const_value.parse_const_value(tokens))
      let location = case value {
        node.ConstValueNode(node) -> node.location
        node.ConstObjectNode(values: _, location:) -> location
        node.ConstListNode(values: _, location:) -> location
      }
      Ok(#(
        node.ConstArgumentNode(
          name: node.NameNode(value: name, location: start),
          value:,
          location: #(start.0, location.1),
        ),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidConstArgument)
  }
}
