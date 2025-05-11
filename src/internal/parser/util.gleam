import errors
import gleam/list
import gleam/option
import gleam/result
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/node

pub fn expect_next(
  tokens: List(token.Token),
  expected: token_kind.TokenKind,
  error: errors.ParseError,
) -> Result(List(token.Token), errors.ParseError) {
  case tokens {
    [#(kind, _), ..tokens] if kind == expected -> Ok(tokens)
    _ -> Error(error)
  }
}

pub fn parse_between(
  start: token_kind.TokenKind,
  end: token_kind.TokenKind,
  tokens: List(token.Token),
  err: errors.ParseError,
  parse_fn: fn(List(token.Token)) ->
    Result(node.NodeWithTokenList(node_type), errors.ParseError),
) -> Result(
  node.NodeWithTokenList(#(List(node_type), position.Position)),
  errors.ParseError,
) {
  use #(#(opt_nodes, end), tokens) <- result.try(parse_between_optional(
    start,
    end,
    tokens,
    parse_fn,
  ))
  case opt_nodes {
    option.None -> Error(err)
    option.Some(nodes) -> Ok(#(#(nodes, end), tokens))
  }
}

pub fn parse_between_optional(
  start: token_kind.TokenKind,
  end: token_kind.TokenKind,
  tokens: List(token.Token),
  parse_fn: fn(List(token.Token)) ->
    Result(node.NodeWithTokenList(node_type), errors.ParseError),
) -> Result(
  node.NodeWithTokenList(#(option.Option(List(node_type)), position.Position)),
  errors.ParseError,
) {
  case tokens {
    [#(kind, _), ..tokens] if start == kind ->
      parse_until(end, tokens, [], parse_fn)
      |> result.map(fn(r) {
        let #(#(nodes, end), tokens) = r
        #(#(nodes |> option.Some, end), tokens)
      })
    _ -> Ok(#(#(option.None, position.new()), tokens))
  }
}

pub fn parse_until(
  end: token_kind.TokenKind,
  tokens: List(token.Token),
  acc: List(node_type),
  parse_fn: fn(List(token.Token)) ->
    Result(node.NodeWithTokenList(node_type), errors.ParseError),
) -> Result(
  node.NodeWithTokenList(#(List(node_type), position.Position)),
  errors.ParseError,
) {
  case tokens {
    [#(kind, #(_, end_pos)), ..tokens] if kind == end ->
      Ok(#(#(acc |> list.reverse, end_pos), tokens))
    tokens -> {
      use #(val, tokens) <- result.try(parse_fn(tokens))
      parse_until(end, tokens, [val, ..acc], parse_fn)
    }
  }
}
