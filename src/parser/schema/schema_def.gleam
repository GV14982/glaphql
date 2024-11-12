import errors
import gleam/list
import gleam/option
import gleam/result
import lexer/position
import lexer/token
import lexer/token_kind
import parser/const_directive
import parser/node

@internal
pub fn parse_schema_extension(
  tokens: List(token.Token),
  start: position.Position,
) -> Result(
  node.NodeWithTokenList(node.TypeSystemExtensionNode),
  errors.ParseError,
) {
  use #(#(directives, end), tokens) <- result.try(
    const_directive.parse_optional_const_directive_list(tokens, []),
  )
  case tokens {
    [#(token_kind.OpenBrace, _), ..tokens] -> {
      use #(#(operation_types, end), tokens) <- result.try(
        parse_root_operation_def_list(tokens, []),
      )
      Ok(#(
        node.SchemaExtensionNode(
          directives:,
          operation_types: option.Some(operation_types),
          location: #(start, end),
        ),
        tokens,
      ))
    }
    tokens -> {
      Ok(#(
        node.SchemaExtensionNode(
          directives:,
          operation_types: option.None,
          location: #(start, end),
        ),
        tokens,
      ))
    }
  }
}

@internal
pub fn parse_schema_definition(
  tokens: List(token.Token),
  description: option.Option(node.DescriptionNode),
  start: position.Position,
) -> Result(
  node.NodeWithTokenList(node.TypeSystemDefinitionNode),
  errors.ParseError,
) {
  use #(#(directives, _), tokens) <- result.try(
    const_directive.parse_optional_const_directive_list(tokens, []),
  )
  case tokens {
    [#(token_kind.OpenBrace, _), ..tokens] -> {
      use #(#(operation_types, end), tokens) <- result.try(
        parse_root_operation_def_list(tokens, []),
      )
      Ok(#(
        node.SchemaDefinitionNode(
          description:,
          directives:,
          operation_types:,
          location: #(start, end),
        ),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidSchemaDefinition)
  }
}

fn parse_root_operation_def_list(
  tokens: List(token.Token),
  defs: List(node.RootOperationTypeDefinition),
) -> Result(
  node.NodeWithTokenList(
    #(List(node.RootOperationTypeDefinition), position.Position),
  ),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.CloseBrace, #(_, end)), ..tokens] ->
      Ok(#(#(defs, end), tokens))
    [
      #(token_kind.Name(op_string), #(start, _)),
      #(token_kind.Colon, _),
      #(token_kind.Name(value), location),
      #(token_kind.Bang, _),
      ..tokens
    ]
    | [
        #(token_kind.Name(op_string), #(start, _)),
        #(token_kind.Colon, _),
        #(token_kind.Name(value), location),
        ..tokens
      ] -> {
      use operation <- result.try(case op_string {
        "query" -> Ok(node.Query)
        "mutation" -> Ok(node.Mutation)
        "subscription" -> Ok(node.Subscription)
        _ -> Error(errors.InvalidRootOperation)
      })
      let named_type = node.NamedTypeNode(node.NameNode(value:, location:))
      parse_root_operation_def_list(
        tokens,
        list.prepend(
          defs,
          node.RootOperationTypeDefinition(named_type:, operation:, location: #(
            start,
            location.1,
          )),
        ),
      )
    }
    _ -> Error(errors.InvalidSchemaDefinition)
  }
}
