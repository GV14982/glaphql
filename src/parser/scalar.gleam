import errors
import gleam/option
import gleam/result
import lexer/position
import lexer/token
import lexer/token_kind
import parser/const_directive.{parse_optional_const_directive_list}
import parser/node

@internal
pub fn parse_scalar_ext(
  tokens: List(token.Token),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeExtensionNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(name), pos), ..rest] -> {
      use #(#(directives, end), rest) <- result.try(
        parse_optional_const_directive_list(rest, []),
      )
      case directives {
        option.None -> Error(errors.InvalidScalarExtension)
        option.Some(directives) ->
          Ok(#(
            node.ScalarTypeExtensionNode(
              name: node.NameNode(value: name, location: pos),
              directives: directives,
              location: #(start, end),
            ),
            rest,
          ))
      }
    }
    _ -> Error(errors.InvalidScalarExtension)
  }
}

@internal
pub fn parse_scalar_def(
  tokens: List(token.Token),
  description: option.Option(node.DescriptionNode),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeDefinitionNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(name), pos), ..rest] -> {
      use #(#(directives, end), rest) <- result.try(
        parse_optional_const_directive_list(rest, []),
      )
      Ok(#(
        node.ScalarTypeDefinitionNode(
          description:,
          name: node.NameNode(value: name, location: pos),
          directives: directives,
          location: #(start, end),
        ),
        rest,
      ))
    }
    _ -> Error(errors.InvalidScalarDefinition)
  }
}
