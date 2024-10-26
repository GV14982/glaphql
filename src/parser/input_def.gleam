import errors
import gleam/option
import gleam/result
import lexer/position
import lexer/token
import lexer/token_kind
import parser/const_directive
import parser/input_value
import parser/node

@internal
pub fn parse_input_ext(
  tokens: List(token.Token),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeExtensionNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(value), location), ..tokens] -> {
      use #(#(directives, _), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      use #(#(fields, end), tokens) <- result.try(
        input_value.parse_optional_input_value_def_list(
          tokens,
          token_kind.OpenBrace,
          token_kind.CloseBrace,
          start,
        ),
      )
      case directives, fields {
        directives, option.Some(fields) ->
          Ok(#(
            node.InputObjectTypeExtensionNode(
              node.InputObjectTypeExtensionWithFieldsNode(
                name: node.NameNode(value:, location:),
                directives:,
                fields:,
                location: #(start, end),
              ),
            ),
            tokens,
          ))
        option.Some(directives), option.None ->
          Ok(#(
            node.InputObjectTypeExtensionNode(
              node.InputObjectTypeExtensionWithDirectivesNode(
                name: node.NameNode(value:, location:),
                directives:,
                location: #(start, end),
              ),
            ),
            tokens,
          ))
        _, _ -> Error(errors.InvalidInputTypeExtension)
      }
    }
    _ -> Error(errors.InvalidInputTypeExtension)
  }
}

@internal
pub fn parse_input_def(
  tokens: List(token.Token),
  description: node.OptionalDescription,
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeDefinitionNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(value), location), ..tokens] -> {
      use #(#(directives, _), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      use #(#(fields, end), tokens) <- result.try(
        input_value.parse_optional_input_value_def_list(
          tokens,
          token_kind.OpenBrace,
          token_kind.CloseBrace,
          start,
        ),
      )
      Ok(#(
        node.InputObjectTypeDefinitionNode(
          name: node.NameNode(value:, location:),
          description:,
          directives:,
          fields:,
          location: #(start, end),
        ),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidInputTypeDefinition)
  }
}
