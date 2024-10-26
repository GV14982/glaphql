import errors
import gleam/list
import gleam/option
import lexer/position
import lexer/token
import lexer/token_kind
import parser/node

@internal
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
        list.append(members, [node.NamedTypeNode(node.NameNode(name, pos))]),
        kind,
        error,
      )
    }
    [#(token_kind.Name(name), pos), ..tokens] -> {
      Ok(#(
        #(
          option.Some(
            list.append(members, [node.NamedTypeNode(node.NameNode(name, pos))]),
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
            val -> option.Some(val)
          },
          pos.1,
        ),
        rest,
      ))
    [] -> Error(error)
  }
}
