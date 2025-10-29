import birdie
import glam/doc
import gleam/option
import internal/codegen/model
import internal/executable/schema/executable
import internal/executable/schema/type_system
import internal/lexer/lexer
import internal/parser/schema/document
import pprint
import simplifile

pub fn generate_models_test() {
  let assert Ok(schema) = simplifile.read("test.schema.graphql")
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  let assert Ok(exec) = executable.from_types(ts, option.None)
  exec
  |> model.generate_models
  |> doc.to_string(80)
  |> birdie.snap("generate test models")
}

pub fn generate_resolver_test() {
  let assert Ok(schema) = simplifile.read("test.schema.graphql")
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  let assert Ok(exec) = executable.from_types(ts, option.None)
  exec.query
  |> model.generate_resolver
  |> doc.to_string(80)
  |> pprint.debug
}
