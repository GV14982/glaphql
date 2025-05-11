import errors
import gleam/list
import gleam/option
import gleam/result
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/node
import internal/parser/schema/input_value_def

@internal
pub fn parse_directive_def(
  tokens: List(token.Token),
  description: option.Option(node.DescriptionNode),
  start: position.Position,
) -> Result(
  node.NodeWithTokenList(node.TypeSystemDefinitionNode),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.At, _), #(token_kind.Name(value), location), ..tokens] -> {
      use #(#(arguments, _), tokens) <- result.try(
        input_value_def.parse_optional_input_value_def_list(
          tokens,
          token_kind.OpenParen,
          token_kind.CloseParen,
        ),
      )
      let #(repeatable, tokens) = case tokens {
        [#(token_kind.Name("repeatable"), _), ..tokens] -> #(True, tokens)
        tokens -> #(False, tokens)
      }
      case tokens {
        [#(token_kind.Name("on"), _), #(token_kind.Pipe, _), ..tokens]
        | [#(token_kind.Name("on"), _), ..tokens] -> {
          use #(#(locations, end), tokens) <- result.try(
            parse_directive_locations(tokens, []),
          )
          Ok(#(
            node.DirectiveDefinitionNode(node.DirectiveDefinition(
              name: node.NameNode(value:, location:),
              location: #(start, end),
              description:,
              arguments:,
              locations:,
              repeatable:,
            )),
            tokens,
          ))
        }
        _ -> Error(errors.InvalidDirectiveDefinition)
      }
    }
    _ -> Error(errors.InvalidDirectiveDefinition)
  }
}

@internal
pub fn parse_directive_locations(
  tokens: List(token.Token),
  locations: List(node.DirectiveLocationNode),
) -> Result(
  node.NodeWithTokenList(#(List(node.DirectiveLocationNode), position.Position)),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.Name(name), location), #(token_kind.Pipe, _), ..tokens] -> {
      use value <- result.try(parse_directive_location(name))
      parse_directive_locations(tokens, [
        node.DirectiveLocationNode(value:, location:),
        ..locations
      ])
    }
    [#(token_kind.Name(name), location), ..tokens] -> {
      use value <- result.try(parse_directive_location(name))
      Ok(#(
        #(
          [node.DirectiveLocationNode(value:, location:), ..locations]
            |> list.reverse,
          location.1,
        ),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidDirectiveDefinition)
  }
}

@internal
pub fn parse_directive_location(
  name: String,
) -> Result(node.DirectiveLocation, errors.ParseError) {
  case name {
    "QUERY" -> Ok(node.ExecutableDirectiveLocation(node.QueryDirective))
    "MUTATION" -> Ok(node.ExecutableDirectiveLocation(node.MutationDirective))
    "SUBSCRIPTION" ->
      Ok(node.ExecutableDirectiveLocation(node.SubscriptionDirective))
    "FIELD" -> Ok(node.ExecutableDirectiveLocation(node.FieldDirective))
    "FRAGMENT_DEFINITION" ->
      Ok(node.ExecutableDirectiveLocation(node.FragmentDefinitionDirective))
    "FRAGMENT_SPREAD" ->
      Ok(node.ExecutableDirectiveLocation(node.FragmentSpreadDirective))
    "INLINE_FRAGMENT" ->
      Ok(node.ExecutableDirectiveLocation(node.InlineFragmentDirective))
    "VARIABLE_DEFINITION" ->
      Ok(node.ExecutableDirectiveLocation(node.VariableDefinitionDirective))
    "SCHEMA" -> Ok(node.TypeSystemDirectiveLocation(node.SchemaDirective))
    "SCALAR" -> Ok(node.TypeSystemDirectiveLocation(node.ScalarDirective))
    "OBJECT" -> Ok(node.TypeSystemDirectiveLocation(node.ObjectDirective))
    "FIELD_DEFINITION" ->
      Ok(node.TypeSystemDirectiveLocation(node.FieldDefinitionDirective))
    "ARGUMENT_DEFINITION" ->
      Ok(node.TypeSystemDirectiveLocation(node.ArgumentDefinitionDirective))
    "INTERFACE" -> Ok(node.TypeSystemDirectiveLocation(node.InterfaceDirective))
    "UNION" -> Ok(node.TypeSystemDirectiveLocation(node.UnionDirective))
    "ENUM" -> Ok(node.TypeSystemDirectiveLocation(node.EnumDirective))
    "ENUM_VALUE" ->
      Ok(node.TypeSystemDirectiveLocation(node.EnumValueDirective))
    "INPUT_OBJECT" ->
      Ok(node.TypeSystemDirectiveLocation(node.InputObjectDirective))
    "INPUT_FIELD_DEFINITION" ->
      Ok(node.TypeSystemDirectiveLocation(node.InputFieldDefinitionDirective))
    _ -> Error(errors.InvalidDirectiveLocation)
  }
}
