import errors
import gleam/list
import gleam/option
import gleam/result
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/arg
import internal/parser/directive
import internal/parser/node

@internal
pub fn parse_field_name(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(
    #(option.Option(node.NameNode), node.NameNode, position.Offset),
  ),
  errors.ParseError,
) {
  case tokens {
    [
      #(token_kind.Name(alias), alias_loc),
      #(token_kind.Colon, _),
      #(token_kind.Name(value), location),
      ..tokens
    ] ->
      Ok(#(
        #(
          option.Some(node.NameNode(value: alias, location: alias_loc)),
          node.NameNode(value:, location:),
          #(alias_loc.0, location.1),
        ),
        tokens,
      ))
    [#(token_kind.Name(value), location), ..tokens] ->
      Ok(#(
        #(option.None, node.NameNode(value:, location:), #(
          location.0,
          location.1,
        )),
        tokens,
      ))
    _ -> Error(errors.InvalidField)
  }
}

@internal
pub fn parse_field(
  tokens: List(token.Token),
) -> Result(node.NodeWithTokenList(node.SelectionNode), errors.ParseError) {
  use #(#(alias, name, #(start, end)), tokens) <- result.try(parse_field_name(
    tokens,
  ))
  use #(#(arguments, _), tokens) <- result.try(arg.parse_optional_args(
    tokens,
    end,
  ))
  use #(#(directives, end), tokens) <- result.try(
    directive.parse_optional_directive_list(tokens, []),
  )
  use #(#(selection_set, end), tokens) <- result.try(
    parse_optional_selection_set(tokens, end),
  )
  Ok(#(
    node.FieldNode(
      alias:,
      name:,
      arguments:,
      directives:,
      selection_set:,
      location: #(start, end),
    ),
    tokens,
  ))
}

@internal
pub fn parse_optional_selection_set(
  tokens: List(token.Token),
  init: position.Position,
) -> Result(
  node.NodeWithTokenList(
    #(option.Option(node.SelectionSetNode), position.Position),
  ),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.OpenBrace, _), ..] -> {
      use #(#(selection_set, end), tokens) <- result.try(parse_selection_set(
        tokens,
      ))
      Ok(#(#(option.Some(selection_set), end), tokens))
    }
    tokens -> Ok(#(#(option.None, init), tokens))
  }
}

@internal
pub fn parse_selection_set(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(#(node.SelectionSetNode, position.Position)),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.OpenBrace, #(start, _)), ..tokens] -> {
      use #(#(selections, end), tokens) <- result.try(
        parse_selections(tokens, []),
      )
      Ok(#(
        #(node.SelectionSetNode(selections:, location: #(start, end)), end),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidSelectionSet)
  }
}

@internal
pub fn parse_selection(
  tokens: List(token.Token),
) -> Result(node.NodeWithTokenList(node.SelectionNode), errors.ParseError) {
  case tokens {
    [
      #(token_kind.Spread, #(start, _)),
      #(token_kind.Name(value), location),
      ..tokens
    ] -> {
      let name = node.NameNode(value:, location:)
      use #(#(directives, end), tokens) <- result.try(
        directive.parse_optional_directive_list(tokens, []),
      )
      Ok(#(
        node.FragmentSpreadNode(name:, directives:, location: #(start, end)),
        tokens,
      ))
    }
    [#(token_kind.Spread, #(start, _)), ..tokens] -> {
      use #(type_condition, tokens) <- result.try(
        parse_optional_named_type_spread(tokens),
      )
      use #(#(directives, _), tokens) <- result.try(
        directive.parse_optional_directive_list(tokens, []),
      )
      use #(#(selection_set, end), tokens) <- result.try(parse_selection_set(
        tokens,
      ))
      Ok(#(
        node.InlineFragmentNode(
          type_condition:,
          directives:,
          selection_set:,
          location: #(start, end),
        ),
        tokens,
      ))
    }
    tokens -> parse_field(tokens)
  }
}

@internal
pub fn parse_optional_named_type_spread(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(option.Option(node.NamedTypeNode)),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.Name("on"), _), #(token_kind.Name(value), location), ..tokens] ->
      Ok(#(
        option.Some(node.NamedTypeNode(node.NameNode(value:, location:))),
        tokens,
      ))
    tokens -> Ok(#(option.None, tokens))
  }
}

@internal
pub fn parse_selections(
  tokens: List(token.Token),
  selections: List(node.SelectionNode),
) -> Result(
  node.NodeWithTokenList(#(List(node.SelectionNode), position.Position)),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.CloseBrace, #(_, end)), ..tokens] ->
      Ok(#(#(selections |> list.reverse, end), tokens))
    tokens -> {
      use #(selection, tokens) <- result.try(parse_selection(tokens))
      parse_selections(tokens, [selection, ..selections])
    }
  }
}
