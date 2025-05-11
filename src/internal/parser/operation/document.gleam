import errors
import gleam/list
import gleam/result
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/node
import internal/parser/operation/definition

@internal
pub fn parse_operations_document(
  tokens: List(token.Token),
  defs: List(node.ExecutableDefinitionNode),
) -> Result(node.Document, errors.ParseError) {
  case tokens {
    [#(token_kind.EOF, _)] -> Ok(node.OperationDocument(defs))
    tokens -> {
      use #(def, tokens) <- result.try(definition.parse_executable(tokens))
      parse_operations_document(tokens, list.prepend(defs, def))
    }
  }
}
