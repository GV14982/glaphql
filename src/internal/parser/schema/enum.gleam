import errors
import gleam/list
import gleam/option
import gleam/result
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/const_directive
import internal/parser/node
import internal/parser/schema/description
import internal/parser/util

@internal
pub fn parse_enum_ext(
  tokens: List(token.Token),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeExtensionNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(name), location), ..tokens] -> {
      use #(#(directives, _), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      use #(#(members, end), tokens) <- result.try(
        parse_optional_enum_members_def(tokens),
      )
      case directives, members {
        option.Some(directives), option.None ->
          Ok(#(
            node.EnumTypeExtensionNode(
              node.EnumTypeExtensionWithoutMembers(
                name: node.NameNode(value: name, location:),
                directives:,
                location: #(start, end),
              ),
            ),
            tokens,
          ))
        _, option.Some(members) ->
          Ok(#(
            node.EnumTypeExtensionNode(
              node.EnumTypeExtensionWithMembers(
                name: node.NameNode(value: name, location:),
                directives:,
                members:,
                location: #(start, end),
              ),
            ),
            tokens,
          ))
        _, _ -> Error(errors.InvalidEnumExtension)
      }
    }
    _ -> Error(errors.InvalidEnumExtension)
  }
}

@internal
pub fn parse_enum_def(
  tokens: List(token.Token),
  description: option.Option(node.DescriptionNode),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeDefinitionNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(name), location), ..tokens] -> {
      use #(#(directives, _), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      use #(#(members, end), tokens) <- result.try(
        parse_optional_enum_members_def(tokens),
      )
      Ok(#(
        node.EnumTypeDefinitionNode(
          node.EnumTypeDefinition(
            name: node.NameNode(value: name, location:),
            description:,
            directives:,
            members:,
            location: #(start, end),
          ),
        ),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidEnumDefinition)
  }
}

@internal
pub fn parse_optional_enum_members_def(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(
    #(option.Option(List(node.EnumValueDefinitionNode)), position.Position),
  ),
  errors.ParseError,
) {
  util.parse_between_optional(
    token_kind.OpenBrace,
    token_kind.CloseBrace,
    tokens,
    parse_enum_member,
  )
}

@internal
pub fn parse_enum_members_def(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(
    #(List(node.EnumValueDefinitionNode), position.Position),
  ),
  errors.ParseError,
) {
  util.parse_between(
    token_kind.OpenBrace,
    token_kind.CloseBrace,
    tokens,
    errors.InvalidEnumDefinition,
    parse_enum_member,
  )
}

@internal
pub fn parse_enum_member_list(
  tokens: List(token.Token),
  members: List(node.EnumValueDefinitionNode),
) -> Result(
  node.NodeWithTokenList(
    #(List(node.EnumValueDefinitionNode), position.Position),
  ),
  errors.ParseError,
) {
  use #(description, tokens) <- result.try(
    description.parse_optional_description(tokens),
  )
  case tokens {
    [#(token_kind.Name(value), location), ..tokens] -> {
      use #(#(directives, end), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      let enum =
        node.EnumValueDefinitionNode(
          name: node.NameNode(value:, location:),
          description:,
          directives:,
          location: #(location.0, end),
        )
      parse_enum_member_list(tokens, [enum, ..members])
    }
    [#(token_kind.CloseBracket, end), ..tokens] ->
      Ok(#(#(members |> list.reverse, end.1), tokens))
    _ -> Error(errors.InvalidEnumMember)
  }
}

@internal
pub fn parse_enum_member(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(node.EnumValueDefinitionNode),
  errors.ParseError,
) {
  use #(description, tokens) <- result.try(
    description.parse_optional_description(tokens),
  )
  case tokens {
    [#(token_kind.Name(value), location), ..tokens] -> {
      use #(#(directives, end), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      Ok(#(
        node.EnumValueDefinitionNode(
          name: node.NameNode(value:, location:),
          description:,
          directives:,
          location: #(location.0, end),
        ),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidEnumMember)
  }
}
