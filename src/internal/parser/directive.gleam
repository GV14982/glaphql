import errors
import gleam/list
import gleam/option
import gleam/pair
import gleam/result
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/arg
import internal/parser/node

@internal
pub fn parse_optional_directive_list(
  tokens: List(token.Token),
  directives: List(node.DirectiveNode),
) -> Result(
  node.NodeWithTokenList(#(node.Directives, position.Position)),
  errors.ParseError,
) {
  use #(opt_val, tokens) <- result.try(parse_optional_directive(tokens))
  case opt_val {
    option.Some(val) ->
      parse_optional_directive_list(tokens, [val, ..directives])
    option.None -> {
      // TODO: This should be passed in as the end positing of the prev character to handle defaults
      use pos <- result.try(
        list.first(tokens)
        |> result.map_error(fn(_e) { errors.EmptyTokenList })
        |> result.map(fn(tkn) { tkn |> pair.second |> pair.second }),
      )
      case directives {
        [] -> Ok(#(#(option.None, pos), tokens))
        _ -> Ok(#(#(option.Some(directives |> list.reverse), pos), tokens))
      }
    }
  }
}

@internal
pub fn parse_optional_directive(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(option.Option(node.DirectiveNode)),
  errors.ParseError,
) {
  case tokens {
    [
      #(token_kind.At, #(start, _)),
      #(token_kind.Name(value), location),
      ..tokens
    ] -> {
      use #(#(arguments, end), tokens) <- result.try(arg.parse_optional_args(
        tokens,
        start,
      ))
      Ok(#(
        option.Some(
          node.DirectiveNode(
            name: node.NameNode(value:, location:),
            arguments:,
            location: #(start, end),
          ),
        ),
        tokens,
      ))
    }
    _ -> Ok(#(option.None, tokens))
  }
}
