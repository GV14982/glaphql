import errors.{type ParseError}
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import lexer/position
import lexer/token.{type Token}
import lexer/token_kind
import parser/node

@internal
pub fn parse_const_value(
  tokens: List(Token),
) -> Result(node.NodeWithTokenList(node.ConstValueNode), ParseError) {
  case tokens {
    [#(token_kind.OpenBracket, start), ..rest] -> {
      use #(#(values, end), rest) <- result.try(
        parse_const_list_value(rest, []),
      )
      Ok(#(node.ConstListNode(values:, location: #(start.0, end)), rest))
    }
    [#(token_kind.OpenBrace, start), ..rest] -> {
      use #(#(values, end), rest) <- result.try(
        parse_const_object_value(rest, []),
      )
      Ok(#(node.ConstObjectNode(values:, location: #(start.0, end)), rest))
    }
    tokens -> {
      use #(val, tokens) <- result.try(parse_const(tokens))
      Ok(#(node.ConstValueNode(val), tokens))
    }
  }
}

@internal
pub fn parse_const(
  tokens: List(Token),
) -> Result(node.NodeWithTokenList(node.ConstNode), ParseError) {
  case tokens {
    [#(token_kind.Name(value), location), ..tokens]
      if value == "true" || value == "false"
    -> Ok(#(node.BooleanValueNode(value: value == "true", location:), tokens))
    [#(token_kind.Name(value), location), ..tokens] if value == "null" ->
      Ok(#(node.NullValueNode(location:), tokens))
    [#(token_kind.Name(value), location), ..rest]
      if value != "null" && value != "true" && value != "false"
    -> Ok(#(node.EnumValueNode(value:, location:), rest))
    [#(token_kind.String(value), location), ..rest] ->
      Ok(#(node.StringValueNode(value:, location:), rest))
    [#(token_kind.Int(value), location), ..rest] -> {
      use value <- result.try(
        int.parse(value) |> result.map_error(fn(_) { errors.InvalidIntValue }),
      )
      Ok(#(node.IntValueNode(value:, location:), rest))
    }
    [#(token_kind.Float(value), location), ..rest] -> {
      use value <- result.try(
        float.parse(value)
        |> result.map_error(fn(_) { errors.InvalidFloatValue }),
      )
      Ok(#(node.FloatValueNode(value:, location:), rest))
    }
    _ -> Error(errors.InvalidConstValue)
  }
}

fn parse_const_list_value(
  tokens: List(Token),
  values: List(node.ConstValueNode),
) -> Result(
  node.NodeWithTokenList(#(List(node.ConstValueNode), position.Position)),
  ParseError,
) {
  case tokens {
    [#(token_kind.CloseBracket, pos), ..rest] -> Ok(#(#(values, pos.1), rest))
    tokens -> {
      use #(value, rest) <- result.try(parse_const_value(tokens))
      parse_const_list_value(rest, list.append(values, [value]))
    }
  }
}

fn parse_const_object_field(
  tokens: List(Token),
) -> Result(node.NodeWithTokenList(node.ConstObjectFieldNode), ParseError) {
  case tokens {
    [#(token_kind.Name(name), start), #(token_kind.Colon, _), ..rest] -> {
      use #(value, rest) <- result.try(parse_const_value(rest))
      let name = node.NameNode(value: name, location: start)
      Ok(#(node.ConstObjectFieldNode(name:, value:), rest))
    }
    _ -> Error(errors.InvalidObjectField)
  }
}

fn parse_const_object_value(
  tokens: List(Token),
  values: List(node.ConstObjectFieldNode),
) -> Result(
  node.NodeWithTokenList(#(List(node.ConstObjectFieldNode), position.Position)),
  ParseError,
) {
  case tokens {
    [#(token_kind.CloseBrace, pos), ..rest] -> Ok(#(#(values, pos.1), rest))
    tokens -> {
      use #(value, rest) <- result.try(parse_const_object_field(tokens))
      parse_const_object_value(rest, list.append(values, [value]))
    }
  }
}
