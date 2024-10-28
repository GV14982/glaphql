import errors
import gleam/list
import gleam/result
import lexer/token
import lexer/token_kind
import parser/definition
import parser/description
import parser/node

@internal
pub fn parse_schema_document(
  tokens: List(token.Token),
  defs: List(node.TypeSystemDefinitionOrExtensionNode),
) -> Result(node.DocumentNode, errors.ParseError) {
  use #(description, tokens) <- result.try(
    description.parse_optional_description(tokens),
  )
  case tokens {
    [#(token_kind.EOF, _)] -> Ok(node.TypeSystemDocument(defs))
    tokens -> {
      use #(def, tokens) <- result.try(definition.parse_type_system(
        tokens,
        description,
      ))
      parse_schema_document(tokens, list.prepend(defs, def))
    }
  }
}

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
