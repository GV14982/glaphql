import errors
import gleam/list
import gleam/option
import gleam/result
import lexer/position
import lexer/token
import lexer/token_kind
import parser/const_directive.{parse_optional_const_directive_list}
import parser/const_value.{parse_const_value}
import parser/description.{parse_optional_description}
import parser/node
import parser/type_node.{parse_type_node}

@internal
pub fn parse_optional_input_value_def_list(
  tokens: List(token.Token),
  open_token: token_kind.TokenKind,
  close_token: token_kind.TokenKind,
  start: position.Position,
) -> Result(
  node.NodeWithTokenList(
    #(option.Option(List(node.InputValueDefinitionNode)), position.Position),
  ),
  errors.ParseError,
) {
  case tokens {
    [#(kind, _), ..tokens] if kind == open_token -> {
      use #(#(input_val_defs, end), tokens) <- result.try(
        parse_input_value_def_list(tokens, [], close_token),
      )
      case input_val_defs {
        [] -> Error(errors.InvalidInputValueList)
        defs -> Ok(#(#(option.Some(defs), end), tokens))
      }
    }
    _ -> Ok(#(#(option.None, start), tokens))
  }
}

@internal
pub fn parse_input_value_def_list(
  tokens: List(token.Token),
  defs: List(node.InputValueDefinitionNode),
  closing_token: token_kind.TokenKind,
) -> Result(
  node.NodeWithTokenList(
    #(List(node.InputValueDefinitionNode), position.Position),
  ),
  errors.ParseError,
) {
  case tokens {
    [#(kind, end), ..tokens] if kind == closing_token ->
      Ok(#(#(defs |> list.reverse, end.1), tokens))
    tokens -> {
      use #(input_value_def, tokens) <- result.try(parse_input_value(tokens))
      parse_input_value_def_list(
        tokens,
        [input_value_def, ..defs],
        closing_token,
      )
    }
  }
}

@internal
pub fn parse_input_value(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(node.InputValueDefinitionNode),
  errors.ParseError,
) {
  use #(desc, tokens) <- result.try(parse_optional_description(tokens))
  case tokens {
    [#(token_kind.Name(name), start), #(token_kind.Colon, _), ..tokens] -> {
      use #(type_node, tokens) <- result.try(parse_type_node(tokens))
      use #(default_value, tokens) <- result.try(parse_optional_default_value(
        tokens,
      ))
      use #(#(directives, end), tokens) <- result.try(
        parse_optional_const_directive_list(tokens, []),
      )
      Ok(#(
        node.InputValueDefinitionNode(
          name: node.NameNode(value: name, location: start),
          type_node:,
          default_value:,
          directives:,
          description: desc,
          location: #(start.0, end),
        ),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidInputValueDefinition)
  }
}

@internal
pub fn parse_optional_default_value(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(option.Option(node.ConstValueNode)),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.Equal, _), ..tokens] -> {
      use #(value, tokens) <- result.try(parse_const_value(tokens))
      Ok(#(option.Some(value), tokens))
    }
    _ -> Ok(#(option.None, tokens))
  }
}
