import errors
import gleam/list
import gleam/result
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/node
import internal/parser/schema/definition
import internal/parser/schema/description

pub fn parse_schema_document(
  tokens: List(token.Token),
  defs: List(node.TypeSystemDefinitionOrExtensionNode),
) -> Result(node.Document, errors.ParseError) {
  use #(description, tokens) <- result.try(
    description.parse_optional_description(tokens),
  )
  case tokens {
    [#(token_kind.EOF, _)] -> Ok(node.SchemaDocument(defs))
    tokens -> {
      use #(def, tokens) <- result.try(definition.parse(tokens, description))
      parse_schema_document(tokens, list.prepend(defs, def))
    }
  }
}
