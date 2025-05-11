import errors
import gleam/option
import gleam/result
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/const_directive
import internal/parser/node
import internal/parser/schema/description
import internal/parser/schema/input_value_def
import internal/parser/type_node
import internal/parser/util

pub fn parse_optional_field_definitions(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(#(node.FieldDefinitions, position.Position)),
  errors.ParseError,
) {
  util.parse_between_optional(
    token_kind.OpenBrace,
    token_kind.CloseBrace,
    tokens,
    parse_field_definition,
  )
}

pub fn parse_field_definition(
  tokens: List(token.Token),
) -> Result(node.NodeWithTokenList(node.FieldDefinitionNode), errors.ParseError) {
  use #(description, tokens) <- result.try(
    description.parse_optional_description(tokens),
  )
  case tokens {
    [#(token_kind.Name(name), pos), ..tokens] -> {
      let start =
        description
        |> option.map(fn(o) { o.location.0 })
        |> option.unwrap(pos.0)
      use #(#(arguments, _), tokens) <- result.try(
        input_value_def.parse_optional_input_value_def_list(
          tokens,
          token_kind.OpenParen,
          token_kind.CloseParen,
        ),
      )
      use tokens <- result.try(
        tokens
        |> util.expect_next(token_kind.Colon, errors.InvalidFieldDefinition),
      )
      use #(type_node, tokens) <- result.try(type_node.parse_type_node(tokens))
      use #(#(directives, end), tokens) <- result.try(
        const_directive.parse_optional_const_directive_list(tokens, []),
      )
      Ok(#(
        node.FieldDefinitionNode(
          description:,
          arguments:,
          name: node.NameNode(value: name, location: pos),
          type_node:,
          directives:,
          location: #(start, end),
        ),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidFieldDefinition)
  }
}
