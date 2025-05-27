import errors
import gleam/result
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/node
import internal/parser/operation/fragment_def
import internal/parser/operation/operation_def

pub fn parse_operation(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(node.OperationDefinitionNode),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.OpenBrace, _), ..] -> {
      use #(operation, tokens) <- result.try(operation_def.parse_operation_def(
        tokens,
        "query",
      ))
      Ok(#(operation, tokens))
    }
    [#(token_kind.Name(val), #(start, _)), ..tokens] -> {
      case val {
        "query" | "mutation" | "subscription" -> {
          use #(operation, tokens) <- result.try(
            operation_def.parse_operation_def(tokens, val),
          )
          Ok(#(operation, tokens))
        }
        // Fragment
        "fragment" -> fragment_def.parse_fragment_def(tokens, start)
        _ -> Error(errors.InvalidExecutableDef)
      }
    }
    _ -> Error(errors.InvalidExecutableDef)
  }
}
