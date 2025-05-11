import errors
import gleam/list
import gleam/option
import gleam/result
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/const_value
import internal/parser/node

pub fn parse_optional_args(
  tokens: List(token.Token),
  default_end: position.Position,
) -> Result(
  node.NodeWithTokenList(
    #(option.Option(List(node.ArgumentNode)), position.Position),
  ),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.OpenParen, _), ..tokens] -> {
      use #(#(args, end), tokens) <- result.try(parse_arg_list(tokens, []))
      Ok(#(#(option.Some(args |> list.reverse), end), tokens))
    }
    tokens -> Ok(#(#(option.None, default_end), tokens))
  }
}

pub fn parse_arg_list(
  tokens: List(token.Token),
  args: List(node.ArgumentNode),
) -> Result(
  node.NodeWithTokenList(#(List(node.ArgumentNode), position.Position)),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.CloseParen, #(_, end)), ..tokens] ->
      Ok(#(#(args, end), tokens))
    [#(token_kind.Name(_), _), ..] -> {
      use #(arg, tokens) <- result.try(parse_arg(tokens))
      parse_arg_list(tokens, [arg, ..args])
    }
    _ -> Error(errors.InvalidArgList)
  }
}

pub fn parse_arg(
  tokens: List(token.Token),
) -> Result(node.NodeWithTokenList(node.ArgumentNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(value), location), #(token_kind.Colon, _), ..tokens] -> {
      use #(#(val, end), tokens) <- result.try(parse_var_or_const(tokens))
      let name = node.NameNode(value:, location:)
      Ok(#(
        node.ArgumentNode(name:, value: val, location: #(location.0, end)),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidArgDef)
  }
}

pub fn parse_var_or_const(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(#(node.ValueNode, position.Position)),
  errors.ParseError,
) {
  case tokens {
    [
      #(token_kind.Dollar, #(start, _)),
      #(token_kind.Name(value), location),
      ..tokens
    ] ->
      Ok(#(
        #(
          node.Variable(
            node.VariableNode(node.NameNode(value:, location:), #(
              start,
              location.1,
            )),
          ),
          location.1,
        ),
        tokens,
      ))
    [#(token_kind.OpenBracket, start), ..tokens] -> {
      use #(#(values, end), tokens) <- result.try(parse_list_value(tokens, []))
      Ok(#(#(node.ListNode(values:, location: #(start.0, end)), end), tokens))
    }
    [#(token_kind.OpenBrace, start), ..tokens] -> {
      use #(#(values, end), tokens) <- result.try(
        parse_object_value(tokens, []),
      )
      Ok(#(#(node.ObjectNode(values:, location: #(start.0, end)), end), tokens))
    }
    tokens ->
      const_value.parse_const(tokens)
      |> result.map(fn(input) {
        let #(val, tokens) = input
        #(#(node.ValueNode(val), val.location.1), tokens)
      })
      |> result.map_error(fn(_err) { errors.InvalidValue })
  }
}

pub fn parse_list_value(
  tokens: List(token.Token),
  values: List(node.ValueNode),
) -> Result(
  node.NodeWithTokenList(#(List(node.ValueNode), position.Position)),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.CloseBracket, pos), ..rest] ->
      Ok(#(#(values |> list.reverse, pos.1), rest))
    tokens -> {
      use #(#(value, _), rest) <- result.try(parse_var_or_const(tokens))
      parse_list_value(rest, [value, ..values])
    }
  }
}

pub fn parse_object_field(
  tokens: List(token.Token),
) -> Result(node.NodeWithTokenList(node.ObjectFieldNode), errors.ParseError) {
  case tokens {
    [#(token_kind.Name(name), location), #(token_kind.Colon, _), ..rest] -> {
      use #(#(value, end), rest) <- result.try(parse_var_or_const(rest))
      let name = node.NameNode(value: name, location:)
      Ok(#(
        node.ObjectFieldNode(name:, value:, location: #(location.0, end)),
        rest,
      ))
    }
    _ -> Error(errors.InvalidObjectField)
  }
}

pub fn parse_object_value(
  tokens: List(token.Token),
  values: List(node.ObjectFieldNode),
) -> Result(
  node.NodeWithTokenList(#(List(node.ObjectFieldNode), position.Position)),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.CloseBrace, pos), ..rest] ->
      Ok(#(#(values |> list.reverse, pos.1), rest))
    tokens -> {
      use #(value, rest) <- result.try(parse_object_field(tokens))
      parse_object_value(rest, [value, ..values])
    }
  }
}
