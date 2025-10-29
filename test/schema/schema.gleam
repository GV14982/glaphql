import birdie
import gleam/option
import internal/executable/schema/executable
import internal/executable/schema/type_system
import internal/lexer/lexer
import internal/parser/schema/document
import pprint
import simplifile

pub fn make_executable_schema_test() {
  let assert Ok(schema) = simplifile.read("test.schema.graphql")
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  let assert Ok(exec) = executable.from_types(ts, option.None)
  exec
  |> pprint.format
  |> birdie.snap(title: "test schema validated")
}
