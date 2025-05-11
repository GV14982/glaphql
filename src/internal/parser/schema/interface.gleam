import errors
import gleam/option
import gleam/result
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/const_directive
import internal/parser/named_type
import internal/parser/node
import internal/parser/schema/field_def

pub fn parse_interface_ext(
  tokens: List(token.Token),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeExtensionNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(value), location), ..tokens] -> {
      use #(#(interfaces, _), tokens) <- result.try(
        parse_optional_interface_implementations(tokens, location.0),
      )
      use #(#(directives, _), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      use #(#(fields, end), rest) <- result.try(
        field_def.parse_optional_field_definitions(tokens),
      )
      case interfaces, directives, fields {
        interfaces, directives, option.Some(fields) ->
          Ok(#(
            node.InterfaceTypeExtensionNode(
              node.InterfaceTypeExtensionWithFieldsNode(
                name: node.NameNode(value:, location:),
                interfaces:,
                directives:,
                fields:,
                location: #(start, end),
              ),
            ),
            rest,
          ))
        interfaces, option.Some(directives), option.None ->
          Ok(#(
            node.InterfaceTypeExtensionNode(
              node.InterfaceTypeExtensionWithDirectivesNode(
                name: node.NameNode(value:, location:),
                interfaces:,
                directives:,
                location: #(start, end),
              ),
            ),
            rest,
          ))
        option.Some(interfaces), option.None, option.None ->
          Ok(#(
            node.InterfaceTypeExtensionNode(
              node.InterfaceTypeExtensionWithImplementsNode(
                name: node.NameNode(value:, location:),
                interfaces:,
                location: #(start, end),
              ),
            ),
            rest,
          ))
        _, _, _ -> Error(errors.InvalidInterfaceExtension)
      }
    }
    _ -> Error(errors.InvalidInterfaceExtension)
  }
}

pub fn parse_interface_def(
  tokens: List(token.Token),
  description: option.Option(node.DescriptionNode),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeDefinitionNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(value), location), ..tokens] -> {
      use #(#(interfaces, _), tokens) <- result.try(
        parse_optional_interface_implementations(tokens, location.0),
      )
      use #(#(directives, _), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      use #(#(fields, end), rest) <- result.try(
        field_def.parse_optional_field_definitions(tokens),
      )
      Ok(#(
        node.InterfaceTypeDefinitionNode(
          node.InterfaceTypeDefinition(
            description: description,
            name: node.NameNode(value:, location:),
            interfaces:,
            directives:,
            fields:,
            location: #(start, end),
          ),
        ),
        rest,
      ))
    }
    _ -> Error(errors.InvalidInterfaceDefinition)
  }
}

pub fn parse_optional_interface_implementations(
  tokens: List(token.Token),
  start: position.Position,
) -> Result(
  node.NodeWithTokenList(
    #(option.Option(List(node.NamedTypeNode)), position.Position),
  ),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.Name("implements"), _), ..tokens] ->
      named_type.parse_named_type_list(
        tokens,
        [],
        token_kind.Amp,
        errors.InvalidImplementsList,
      )
    _ -> Ok(#(#(option.None, start), tokens))
  }
}
