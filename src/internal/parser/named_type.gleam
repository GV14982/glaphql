import errors
import gleam/list
import gleam/option
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/node

pub fn parse_named_type_list(
  tokens: List(token.Token),
  members: List(node.NamedTypeNode),
  separator: token_kind.TokenKind,
  error: errors.ParseError,
) -> Result(
  node.NodeWithTokenList(
    #(option.Option(List(node.NamedTypeNode)), position.Position),
  ),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.Name(name), pos), #(kind, _), ..tokens] if kind == separator -> {
      parse_named_type_list(
        tokens,
        [node.NamedTypeNode(node.NameNode(name, pos)), ..members],
        kind,
        error,
      )
    }
    [#(token_kind.Name(name), pos), ..tokens] -> {
      Ok(#(
        #(
          option.Some(
            [node.NamedTypeNode(node.NameNode(name, pos)), ..members]
            |> list.reverse,
          ),
          pos.1,
        ),
        tokens,
      ))
    }
    [#(_, pos), ..rest] ->
      Ok(#(
        #(
          case members {
            [] -> option.None
            val -> option.Some(val |> list.reverse)
          },
          pos.1,
        ),
        rest,
      ))
    [] -> Error(error)
  }
}
