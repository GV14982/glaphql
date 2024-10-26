import errors
import gleam/result
import lexer/position
import lexer/token
import lexer/token_kind
import parser/directive
import parser/node
import parser/selection

pub fn parse_fragment_def(
  tokens: List(token.Token),
  start: position.Position,
) -> Result(
  node.NodeWithTokenList(node.ExecutableDefinitionNode),
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
        selection.parse_selection_set(tokens),
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
