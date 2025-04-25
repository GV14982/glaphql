import errors
import gleam/option
import gleam/result
import lexer/position
import lexer/token
import lexer/token_kind
import parser/const_directive
import parser/named_type
import parser/node

@internal
pub fn parse_union_ext(
  tokens: List(token.Token),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeExtensionNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(value), pos), ..tokens] -> {
      use #(#(directives, _), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      use #(#(members, end), tokens) <- result.try(
        tokens |> parse_optional_union_members(pos.0),
      )
      case directives, members {
        directives, option.Some(members) ->
          Ok(#(
            node.UnionTypeExtensionNode(node.UnionTypeExtensionWithMembers(
              name: node.NameNode(value:, location: pos),
              directives:,
              location: #(start, end),
              members:,
            )),
            tokens,
          ))
        option.Some(directives), option.None ->
          Ok(#(
            node.UnionTypeExtensionNode(
              node.UnionTypeExtensionWithDirectives(
                name: node.NameNode(value:, location: pos),
                directives:,
                location: #(start, end),
              ),
            ),
            tokens,
          ))
        _, _ -> Error(errors.InvalidUnionExtension)
      }
    }
    _ -> Error(errors.InvalidUnionExtension)
  }
}

@internal
pub fn parse_union_def(
  tokens: List(token.Token),
  description: option.Option(node.DescriptionNode),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeDefinitionNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(value), pos), ..tokens] -> {
      use #(#(directives, _), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      use #(#(members, end), tokens) <- result.try(
        tokens |> parse_optional_union_members(pos.0),
      )
      Ok(#(
        node.UnionTypeDefinitionNode(node.UnionTypeDefinition(
          description:,
          name: node.NameNode(value:, location: pos),
          directives:,
          location: #(start, end),
          members:,
        )),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidUnionDefinition)
  }
}

fn parse_optional_union_members(
  tokens: List(token.Token),
  start: position.Position,
) -> Result(
  node.NodeWithTokenList(
    #(option.Option(List(node.NamedTypeNode)), position.Position),
  ),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.Equal, _), #(token_kind.Name(name), pos), ..tokens] -> {
      named_type.parse_named_type_list(
        [#(token_kind.Name(name), pos), ..tokens],
        [],
        token_kind.Pipe,
        errors.InvalidUnionDefinition,
      )
    }
    [#(token_kind.Equal, _), #(token_kind.Pipe, _), ..tokens] -> {
      named_type.parse_named_type_list(
        tokens,
        [],
        token_kind.Pipe,
        errors.InvalidUnionDefinition,
      )
    }
    _ -> Ok(#(#(option.None, start), tokens))
  }
}
