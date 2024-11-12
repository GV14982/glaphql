import birdie
import gleam/result
import gleam/string
import lexer/lexer
import parser/operation/document
import pprint
import simplifile

pub fn parse_executable_document_test() {
  use schema <- result.try(
    simplifile.read("test.operation.graphql")
    |> result.map(string.trim)
    |> result.map_error(fn(_e) { Nil }),
  )
  use lexed <- result.try(lexer.lex(schema) |> result.map_error(fn(_e) { Nil }))
  let parsed = document.parse_operations_document(lexed, [])
  parsed
  |> pprint.format
  |> birdie.snap(title: "test operations parsed")
  Ok(Nil)
}
