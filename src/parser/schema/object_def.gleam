import errors
import gleam/option
import gleam/result
import lexer/position
import lexer/token
import lexer/token_kind
import parser/const_directive
import parser/node
import parser/schema/field_def
import parser/schema/interface

@internal
pub fn parse_object_ext(
  tokens: List(token.Token),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeExtensionNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(value), location), ..tokens] -> {
      use #(#(interfaces, _), tokens) <- result.try(
        interface.parse_optional_interface_implementations(tokens, location.0),
      )
      use #(#(directives, _), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      use #(#(fields, end), tokens) <- result.try(
        field_def.parse_optional_field_definitions(tokens),
      )
      let ext_node_result = case interfaces, directives, fields {
        interfaces, directives, option.Some(fields) ->
          Ok(#(
            node.ObjectTypeExtensionWithFields(
              name: node.NameNode(value:, location:),
              interfaces:,
              directives:,
              fields:,
              location: #(start, end),
            ),
            tokens,
          ))
        interfaces, option.Some(directives), option.None ->
          Ok(#(
            node.ObjectTypeExtensionWithDirectives(
              name: node.NameNode(value:, location:),
              interfaces:,
              directives:,
              location: #(start, end),
            ),
            tokens,
          ))
        option.Some(interfaces), option.None, option.None ->
          Ok(#(
            node.ObjectTypeExtensionWithInterfaces(
              name: node.NameNode(value:, location:),
              interfaces:,
              location: #(start, end),
            ),
            tokens,
          ))
        option.None, option.None, option.None ->
          Error(errors.InvalidObjectTypeExtension)
      }
      use #(node, tokens) <- result.try(ext_node_result)
      Ok(#(node.ObjectTypeExtensionNode(node:), tokens))
    }
    _ -> Error(errors.InvalidObjectTypeExtension)
  }
}

@internal
pub fn parse_object_def(
  tokens: List(token.Token),
  description: node.OptionalDescription,
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeDefinitionNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(value), location), ..tokens] -> {
      use #(#(interfaces, _), tokens) <- result.try(
        interface.parse_optional_interface_implementations(tokens, location.0),
      )
      use #(#(directives, _), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      use #(#(fields, end), tokens) <- result.try(
        field_def.parse_optional_field_definitions(tokens),
      )
      Ok(#(
        node.ObjectTypeDefinitionNode(
          node.ObjectTypeDefinition(
            name: node.NameNode(value:, location:),
            description:,
            directives:,
            fields:,
            interfaces:,
            location: #(start, end),
          ),
        ),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidObjectTypeDefinition)
  }
}
