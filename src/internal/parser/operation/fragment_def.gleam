import errors
import gleam/result
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/directive
import internal/parser/node
import internal/parser/operation/selection_set

pub fn parse_fragment_def(
  tokens: List(token.Token),
  start: position.Position,
) -> Result(
  node.NodeWithTokenList(node.OperationDefinitionNode),
  errors.ParseError,
) {
  case tokens {
    [
      #(token_kind.Name(value), location),
      #(token_kind.Name("on"), _),
      #(token_kind.Name(type_name), type_name_location),
      ..tokens
    ] -> {
      let name = node.NameNode(value:, location:)
      let type_condition =
        node.NamedTypeNode(node.NameNode(
          value: type_name,
          location: type_name_location,
        ))
      use #(#(directives, _), tokens) <- result.try(
        directive.parse_optional_directive_list(tokens, []),
      )
      use #(#(selection_set, end), tokens) <- result.try(
        selection_set.parse_selection_set(tokens),
      )
      let fragment =
        node.FragmentDefinitionNode(
          name:,
          type_condition:,
          directives:,
          selection_set:,
          location: #(start, end),
        )
      Ok(#(fragment, tokens))
    }
    _ -> Error(errors.InvalidFragmentDef)
  }
}
