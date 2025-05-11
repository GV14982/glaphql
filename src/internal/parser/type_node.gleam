import errors
import gleam/result
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/node

pub fn parse_type_node(
  tokens: List(token.Token),
) -> Result(node.NodeWithTokenList(node.TypeNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(value), start), #(token_kind.Bang, end), ..tokens] -> {
      Ok(#(
        node.NonNullTypeNode(
          type_node: node.NamedTypeNode(node.NameNode(value:, location: start)),
          location: #(start.0, end.1),
        ),
        tokens,
      ))
    }
    [#(token_kind.Name(value), location), ..tokens] -> {
      Ok(#(
        node.NullableTypeNode(
          type_node: node.NamedTypeNode(node.NameNode(value:, location:)),
          location:,
        ),
        tokens,
      ))
    }
    [#(token_kind.OpenBracket, start), ..tokens] -> {
      use #(type_node, tokens) <- result.try(parse_type_node(tokens))
      case tokens {
        [#(token_kind.CloseBracket, _), #(token_kind.Bang, end), ..tokens] -> {
          Ok(#(
            node.NonNullListTypeNode(type_node:, location: #(start.0, end.1)),
            tokens,
          ))
        }
        [#(token_kind.CloseBracket, end), ..tokens] -> {
          Ok(#(
            node.NullableListTypeNode(type_node:, location: #(start.0, end.1)),
            tokens,
          ))
        }
        _ -> Error(errors.InvalidFieldDefinition)
      }
    }
    _ -> Error(errors.InvalidFieldDefinition)
  }
}
