import errors
import gleam/option
import gleam/result
import lexer/position
import lexer/token
import lexer/token_kind
import parser/const_directive
import parser/named_type
import parser/node
import parser/schema/field_def

@internal
pub fn parse_interface_ext(
  tokens: List(token.Token),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeExtensionNode), errors.ParseError) {
  case tokens {
    [
      #(token_kind.Name(value), location),
      #(token_kind.Name("implements"), _),
      ..tokens
    ]
    | [#(token_kind.Name(value), location), ..tokens] -> {
      use #(#(interfaces, _), tokens) <- result.try(
        named_type.parse_named_type_list(
          tokens,
          [],
          token_kind.Amp,
          errors.InvalidInterfaceDefinition,
        ),
      )
      use #(#(directives, _), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      use #(#(fields, end), rest) <- result.try(
        field_def.parse_field_definitions(tokens, []),
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

@internal
pub fn parse_interface_def(
  tokens: List(token.Token),
  description: option.Option(node.DescriptionNode),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeDefinitionNode), errors.ParseError) {
  case tokens {
    [
      #(token_kind.Name(value), location),
      #(token_kind.Name("implements"), _),
      ..tokens
    ]
    | [#(token_kind.Name(value), location), ..tokens] -> {
      use #(#(interfaces, _), tokens) <- result.try(
        named_type.parse_named_type_list(
          tokens,
          [],
          token_kind.Amp,
          errors.InvalidInterfaceDefinition,
        ),
      )
      use #(#(directives, _), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      use #(#(fields, end), rest) <- result.try(
        field_def.parse_field_definitions(tokens, []),
      )
      Ok(#(
        node.InterfaceTypeDefinitionNode(
          description: description,
          name: node.NameNode(value:, location:),
          interfaces:,
          directives:,
          fields:,
          location: #(start, end),
        ),
        rest,
      ))
    }
    _ -> Error(errors.InvalidInterfaceDefinition)
  }
}
