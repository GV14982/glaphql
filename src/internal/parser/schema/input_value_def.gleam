import errors
import gleam/option
import gleam/result
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/const_directive
import internal/parser/default_value
import internal/parser/node
import internal/parser/schema/description
import internal/parser/type_node
import internal/parser/util

pub fn parse_optional_input_value_def_list(
  tokens: List(token.Token),
  start: token_kind.TokenKind,
  end: token_kind.TokenKind,
) -> Result(
  node.NodeWithTokenList(
    #(option.Option(List(node.InputValueDefinitionNode)), position.Position),
  ),
  errors.ParseError,
) {
  util.parse_between_optional(start, end, tokens, parse_input_value)
}

pub fn parse_input_value_def_list(
  tokens: List(token.Token),
  start: token_kind.TokenKind,
  end: token_kind.TokenKind,
) -> Result(
  node.NodeWithTokenList(
    #(List(node.InputValueDefinitionNode), position.Position),
  ),
  errors.ParseError,
) {
  util.parse_between(
    start,
    end,
    tokens,
    errors.InvalidInputTypeDefinition,
    parse_input_value,
  )
}

pub fn parse_input_value(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(node.InputValueDefinitionNode),
  errors.ParseError,
) {
  use #(desc, tokens) <- result.try(description.parse_optional_description(
    tokens,
  ))
  case tokens {
    [#(token_kind.Name(name), start), #(token_kind.Colon, _), ..tokens] -> {
      use #(type_node, tokens) <- result.try(type_node.parse_type_node(tokens))
      use #(default_value, tokens) <- result.try(default_value.parse_optional(
        tokens,
      ))
      use #(#(directives, end), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
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
