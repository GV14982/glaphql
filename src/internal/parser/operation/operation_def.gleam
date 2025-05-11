import errors
import gleam/option
import gleam/result
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/directive
import internal/parser/node
import internal/parser/operation/selection_set
import internal/parser/operation/variable_def

@internal
pub fn parse_operation_def(
  tokens: List(token.Token),
  operation_type: String,
) -> Result(
  node.NodeWithTokenList(node.OperationDefinitionNode),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.OpenBrace, #(start, _)), ..] ->
      parse_unnamed_query(tokens, start)
    [#(token_kind.Name(value), location), ..tokens] -> {
      let name = node.NameNode(value:, location:)
      parse_named_operation(tokens, name, location.0, operation_type)
    }
    _ -> Error(errors.InvalidOperationDef)
  }
}

@internal
pub fn parse_unnamed_query(
  tokens: List(token.Token),
  start: position.Position,
) -> Result(
  node.NodeWithTokenList(node.OperationDefinitionNode),
  errors.ParseError,
) {
  use #(#(selection_set, end), tokens) <- result.try(
    selection_set.parse_selection_set(tokens),
  )
  Ok(#(
    node.QueryOperationNode(
      name: option.None,
      variable_definitions: option.None,
      directives: option.None,
      selection_set:,
      location: #(start, end),
    ),
    tokens,
  ))
}

@internal
pub fn parse_named_operation(
  tokens: List(token.Token),
  name: node.NameNode,
  start: position.Position,
  operation_type: String,
) -> Result(
  node.NodeWithTokenList(node.OperationDefinitionNode),
  errors.ParseError,
) {
  use #(variable_definitions, tokens) <- result.try(
    variable_def.parse_optional_variable_definitions(tokens),
  )
  use #(#(directives, _), tokens) <- result.try(
    directive.parse_optional_directive_list(tokens, []),
  )
  use #(#(selection_set, end), tokens) <- result.try(
    selection_set.parse_selection_set(tokens),
  )
  let location = #(start, end)
  case operation_type {
    "query" ->
      Ok(#(
        node.QueryOperationNode(
          name: option.Some(name),
          variable_definitions:,
          directives:,
          selection_set:,
          location:,
        ),
        tokens,
      ))
    "mutation" ->
      Ok(#(
        node.MutationOperationNode(
          name:,
          variable_definitions:,
          directives:,
          selection_set:,
          location:,
        ),
        tokens,
      ))
    "subscription" ->
      Ok(#(
        node.SubscriptionOperationNode(
          name:,
          variable_definitions:,
          directives:,
          selection_set:,
          location:,
        ),
        tokens,
      ))
    _ -> Error(errors.InvalidOperationType)
  }
}
