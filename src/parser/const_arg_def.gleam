import errors
import gleam/list
import gleam/option
import gleam/result
import lexer/position
import lexer/token
import lexer/token_kind
import parser/const_value.{parse_const_value}
import parser/node

@internal
pub fn parse_optional_const_arg_defs(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(
    #(option.Option(List(node.ConstArgumentNode)), position.Position),
  ),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.OpenParen, _), ..rest] -> {
      parse_const_arg_def_list(rest, [])
    }
    [#(_kind, #(_, end)), ..] -> Ok(#(#(option.None, end), tokens))
    [] -> Error(errors.InvalidConstArgument)
  }
}

fn parse_const_arg_def_list(
  tokens: List(token.Token),
  args: List(node.ConstArgumentNode),
) -> Result(
  node.NodeWithTokenList(
    #(option.Option(List(node.ConstArgumentNode)), position.Position),
  ),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.Name(name), start), #(token_kind.Colon, _), ..rest] -> {
      use #(value, rest) <- result.try(parse_const_value(rest))
      let location = case value {
        node.ConstValueNode(node) -> node.location
        node.ConstObjectNode(values: _, location:) -> location
        node.ConstListNode(values: _, location:) -> location
      }
      parse_const_arg_def_list(
        rest,
        list.append(args, [
          node.ConstArgumentNode(
            name: node.NameNode(value: name, location: start),
            value:,
            location: #(start.0, location.1),
          ),
        ]),
      )
    }
    [#(token_kind.CloseParen, pos), ..rest] ->
      Ok(#(#(option.Some(args), pos.1), rest))
    _ -> Error(errors.InvalidConstArgument)
  }
}
