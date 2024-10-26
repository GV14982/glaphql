import errors
import gleam/option.{type Option}
import gleam/result
import lexer/position
import lexer/token
import lexer/token_kind
import parser/const_directive.{parse_optional_const_directive_list}
import parser/named_type.{parse_named_type_list}
import parser/node

@internal
pub fn parse_union_ext(
  tokens: List(token.Token),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeExtensionNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(value), pos), ..rest] -> {
      use #(#(directives, _), rest) <- result.try(
        parse_optional_const_directive_list(rest, []),
      )
      use #(#(members, end), rest) <- result.try(parse_named_type_list(
        rest,
        [],
        token_kind.Pipe,
        errors.InvalidUnionDefinition,
      ))
      case directives, members {
        directives, option.Some(members) ->
          Ok(#(
            node.UnionTypeExtensionNode(node.UnionTypeExtensionWithMembers(
              name: node.NameNode(value:, location: pos),
              directives:,
              location: #(start, end),
              members:,
            )),
            rest,
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
            rest,
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
  description: Option(node.DescriptionNode),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeDefinitionNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(value), pos), ..rest] -> {
      use #(#(directives, _), rest) <- result.try(
        parse_optional_const_directive_list(rest, []),
      )
      use #(#(members, end), rest) <- result.try(parse_named_type_list(
        rest,
        [],
        token_kind.Pipe,
        errors.InvalidUnionDefinition,
      ))
      Ok(#(
        node.UnionTypeDefinitionNode(
          description:,
          name: node.NameNode(value:, location: pos),
          directives:,
          location: #(start, end),
          members:,
        ),
        rest,
      ))
    }
    _ -> Error(errors.InvalidUnionDefinition)
  }
}
