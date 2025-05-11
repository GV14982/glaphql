import errors
import gleam/list
import gleam/option
import gleam/result
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/const_directive
import internal/parser/default_value
import internal/parser/node
import internal/parser/type_node as tn

@internal
pub fn parse_optional_variable_definitions(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(option.Option(List(node.VariableDefinitionNode))),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.OpenParen, _), ..tokens] -> {
      use #(defs, tokens) <- result.try(
        parse_variable_definition_list(tokens, []),
      )
      Ok(#(option.Some(defs), tokens))
    }
    tokens -> Ok(#(option.None, tokens))
  }
}

@internal
pub fn parse_variable_definition_list(
  tokens: List(token.Token),
  defs: List(node.VariableDefinitionNode),
) -> Result(
  node.NodeWithTokenList(List(node.VariableDefinitionNode)),
  errors.ParseError,
) {
  case tokens {
    [
      #(token_kind.Dollar, #(start, _)),
      #(token_kind.Name(value), location),
      #(token_kind.Colon, _),
      ..tokens
    ] -> {
      let name = node.NameNode(value:, location:)
      let variable_node =
        node.VariableNode(name:, location: #(start, location.0))
      use #(type_node, tokens) <- result.try(tn.parse_type_node(tokens))
      use #(default_value, tokens) <- result.try(default_value.parse_optional(
        tokens,
      ))
      use #(#(directives, end), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      let node =
        node.VariableDefinitionNode(
          variable_node:,
          type_node:,
          default_value:,
          directives:,
          location: #(start, end),
        )
      parse_variable_definition_list(tokens, [node, ..defs])
    }
    [#(token_kind.CloseParen, _), ..tokens] ->
      Ok(#(defs |> list.reverse, tokens))
    _ -> Error(errors.InvalidVariableDefinition)
  }
}
