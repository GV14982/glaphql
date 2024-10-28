import errors
import gleam/list
import gleam/option
import gleam/result
import lexer/position
import lexer/token
import lexer/token_kind
import parser/const_directive.{parse_optional_const_directive_list}
import parser/description.{parse_optional_description}
import parser/input_value.{parse_optional_input_value_def_list}
import parser/node
import parser/type_node.{parse_type_node}

@internal
pub fn parse_field_definitions(
  tokens: List(token.Token),
  defs: List(node.FieldDefinitionNode),
) -> Result(
  node.NodeWithTokenList(#(node.FieldDefinitions, position.Position)),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.CloseBrace, end), ..rest] ->
      Ok(#(#(option.Some(defs |> list.reverse), end.1), rest))
    tokens -> {
      use #(desc, tokens) <- result.try(parse_optional_description(tokens))
      case tokens {
        [#(token_kind.Name(name), pos), ..tokens] -> {
          use #(field_def, tokens) <- result.try(parse_field_definition(
            node.NameNode(value: name, location: pos),
            tokens,
            desc,
            pos.0,
          ))
          parse_field_definitions(tokens, [field_def, ..defs])
        }
        _ -> Error(errors.InvalidFieldDefinition)
      }
    }
  }
}

@internal
pub fn parse_field_definition(
  name: node.NameNode,
  tokens: List(token.Token),
  desc: node.OptionalDescription,
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.FieldDefinitionNode), errors.ParseError) {
  use #(#(arguments, _), tokens) <- result.try(
    parse_optional_input_value_def_list(
      tokens,
      token_kind.OpenParen,
      token_kind.CloseParen,
      start,
    ),
  )
  case tokens {
    [#(token_kind.Colon, _), ..tokens] -> {
      use #(type_node, tokens) <- result.try(parse_type_node(tokens))
      use #(#(directives, end), tokens) <- result.try(
        parse_optional_const_directive_list(tokens, []),
      )
      Ok(#(
        node.FieldDefinitionNode(
          description: desc,
          arguments:,
          name:,
          type_node:,
          directives:,
          location: #(start, end),
        ),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidFieldDefinition)
  }
}
