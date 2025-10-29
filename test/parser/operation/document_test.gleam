import birdie
import internal/lexer/lexer
import internal/parser/operation/document
import pprint
import simplifile

pub fn parse_executable_document_test() {
  let assert Ok(value) = simplifile.read("test.operation.graphql")
  let assert Ok(lexed) = lexer.lex(value)
  let assert Ok(parsed) = document.parse_operations_document(lexed, [])
  parsed
  |> pprint.format
  |> birdie.snap(title: "test operations parsed")
}
