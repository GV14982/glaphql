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

pub fn parse_operation_def(
  tokens: List(token.Token),
  operation_type: String,
) -> Result(
  node.NodeWithTokenList(node.OperationDefinitionNode),
  errors.ParseError,
) {
  use operation_type <- result.try(root_operation_from_string(operation_type))
  case tokens {
    [#(token_kind.OpenBrace, #(start, _)), ..] ->
      parse_unnamed_operation(tokens, start, operation_type)
    [#(token_kind.Name(value), location), ..tokens] -> {
      let name = node.NameNode(value:, location:)
      parse_named_operation(tokens, name, location.0, operation_type)
    }
    _ -> Error(errors.InvalidOperationDef)
  }
}

pub fn parse_unnamed_operation(
  tokens: List(token.Token),
  start: position.Position,
  operation_type: node.OperationType,
) -> Result(
  node.NodeWithTokenList(node.OperationDefinitionNode),
  errors.ParseError,
) {
  use #(#(selection_set, end), tokens) <- result.try(
    selection_set.parse_selection_set(tokens),
  )

  Ok(#(
    node.AnonymousOperationDefinitionNode(
      operation_type:,
      directives: option.None,
      selection_set:,
      location: #(start, end),
    ),
    tokens,
  ))
}

pub fn parse_named_operation(
  tokens: List(token.Token),
  name: node.NameNode,
  start: position.Position,
  operation_type: node.OperationType,
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
  Ok(#(
    node.NamedOperationDefinitionNode(
      name:,
      variable_definitions:,
      operation_type:,
      directives:,
      selection_set:,
      location: #(start, end),
    ),
    tokens,
  ))
}

fn root_operation_from_string(
  str: String,
) -> Result(node.OperationType, errors.ParseError) {
  case str {
    "query" -> node.Query |> Ok
    "mutation" -> node.Mutation |> Ok
    "subscription" -> node.Subscription |> Ok
    val -> Error(errors.InvalidOperationType(val))
  }
}
