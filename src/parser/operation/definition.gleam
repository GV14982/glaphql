import errors
import gleam/result
import lexer/token
import lexer/token_kind
import parser/node
import parser/operation/fragment_def
import parser/operation/operation_def

@internal
pub fn parse_executable(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(node.ExecutableDefinitionNode),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.Name(val), #(start, _)), ..tokens] -> {
      case val {
        "query" | "mutation" | "subscription" -> {
          use #(operation, tokens) <- result.try(
            operation_def.parse_operation_def(tokens, val),
          )
          Ok(#(node.OperationDefinitionNode(operation), tokens))
        }
        // Fragment
        "fragment" -> fragment_def.parse_fragment_def(tokens, start)
        _ -> Error(errors.InvalidExecutableDef)
      }
    }
    _ -> Error(errors.InvalidExecutableDef)
  }
}
