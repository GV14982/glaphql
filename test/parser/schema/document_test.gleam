import birdie
import internal/lexer/lexer
import internal/parser/schema/document
import pprint
import simplifile

pub fn parse_schema_document_test() {
  let assert Ok(value) = simplifile.read("test.schema.graphql")
  let assert Ok(lexed) = lexer.lex(value)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  parsed
  |> pprint.format
  |> birdie.snap(title: "test schema parsed")
}
