import errors
import gleam/option
import lexer/token
import lexer/token_kind
import parser/node

pub fn parse_optional_description(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(option.Option(node.DescriptionNode)),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.String(value), location), ..tokens] ->
      Ok(#(option.Some(node.DescriptionNode(value:, location:)), tokens))
    [] -> Error(errors.InvalidDescription)
    _ -> Ok(#(option.None, tokens))
  }
}