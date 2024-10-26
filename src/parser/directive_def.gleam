import errors
import gleam/list
import gleam/option
import gleam/result
import lexer/position
import lexer/token
import lexer/token_kind
import parser/const_arg_def
import parser/node

pub fn parse_directive_def(
  tokens: List(token.Token),
  description: option.Option(node.DescriptionNode),
  start: position.Position,
) -> Result(
  node.NodeWithTokenList(node.TypeSystemDefinitionNode),
  errors.ParseError,
) {
  case tokens {
    [
      #(token_kind.Name("directive"), _),
      #(token_kind.At, _),
      #(token_kind.Name(value), location),
      ..tokens
    ] -> {
      use #(#(arguments, _), tokens) <- result.try(
        const_arg_def.parse_optional_const_arg_defs(tokens),
      )
      let #(repeatable, tokens) = case tokens {
        [#(token_kind.Name("repeatable"), _), ..tokens] -> #(True, tokens)
        tokens -> #(False, tokens)
      }
      case tokens {
        [#(token_kind.Name("on"), _), ..tokens] -> {
          use #(#(locations, end), tokens) <- result.try(
            parse_directive_locations(tokens, []),
          )
          Ok(#(
            node.DirectiveDefinitionNode(
              name: node.NameNode(value:, location:),
              location: #(start, end),
              description:,
              arguments:,
              locations:,
              repeatable:,
            ),
            tokens,
          ))
        }
        _ -> Error(errors.InvalidDirectiveDefinition)
      }
    }
    _ -> Error(errors.InvalidDirectiveDefinition)
  }
}

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
      parse_directive_locations(
        tokens,
        list.append(locations, [node.DirectiveLocationNode(value:, location:)]),
      )
    }
    [#(token_kind.Name(name), location), ..tokens] -> {
      use value <- result.try(parse_directive_location(name))
      Ok(#(
        #(
          list.append(locations, [node.DirectiveLocationNode(value:, location:)]),
          location.1,
        ),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidDirectiveDefinition)
  }
}

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
