import errors
import gleam/list
import gleam/result
import lexer/token
import lexer/token_kind
import parser/node
import parser/schema/definition
import parser/schema/description

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
      use #(def, tokens) <- result.try(definition.parse(tokens, description))
      parse_schema_document(tokens, list.prepend(defs, def))
    }
  }
}
