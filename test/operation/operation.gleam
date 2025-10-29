import gleam/dict
import gleam/option
import internal/executable/operation/executable
import internal/executable/schema/executable as schema_executable
import internal/executable/schema/type_system
import internal/executable/types
import internal/lexer/lexer
import internal/parser/operation/document
import internal/parser/schema/document as schema_document
import simplifile

pub fn make_executable_schema_test() {
  let assert Ok(schema) = simplifile.read("test.schema.graphql")
  let assert Ok(lexed) = lexer.lex(schema)
  let assert Ok(parsed) = schema_document.parse_schema_document(lexed, [])
  let assert Ok(ts) = type_system.from_schema_doc(parsed)
  let assert Ok(executable_schema) =
    schema_executable.from_types(ts, option.None)

  let assert Ok(file) = simplifile.read("test.operation.graphql")

  let assert Ok(lexed) = lexer.lex(file)
  let assert Ok(parsed) = document.parse_operations_document(lexed, [])
  let assert Ok(_) =
    executable.make_executable(
      parsed,
      executable_schema,
      option.Some("GetUser"),
      dict.new()
        |> dict.insert(
          "userId",
          types.ExecutableConstScalar(types.ExecutableStringVal("id-123")),
        ),
    )
}
