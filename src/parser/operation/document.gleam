import errors
import gleam/list
import gleam/result
import lexer/token
import lexer/token_kind
import parser/node
import parser/operation/definition

@internal
pub fn parse_operations_document(
  tokens: List(token.Token),
  defs: List(node.ExecutableDefinitionNode),
) -> Result(node.DocumentNode, errors.ParseError) {
  case tokens {
    [#(token_kind.EOF, _)] -> Ok(node.ExecutableDocumentNode(defs))
    tokens -> {
      use #(def, tokens) <- result.try(definition.parse_executable(tokens))
      parse_operations_document(tokens, list.prepend(defs, def))
    }
  }
}
