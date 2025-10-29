import birdie
import internal/lexer/lexer
import pprint
import simplifile

pub fn schema_lex_test() {
  let assert Ok(value) = simplifile.read("test.schema.graphql")
  let assert Ok(lexed) = lexer.lex(value)
  lexed
  |> pprint.format
  |> birdie.snap(title: "test schema lexed")
}

pub fn operations_lex_test() {
  let assert Ok(value) = simplifile.read("test.operation.graphql")
  let assert Ok(lexed) = lexer.lex(value)
  lexed
  |> pprint.format
  |> birdie.snap(title: "test operations lexed")
}
