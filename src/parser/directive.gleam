import errors.{type ParseError}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import lexer/position
import lexer/token.{type Token}
import lexer/token_kind
import parser/arg.{parse_optional_args}
import parser/node

@internal
pub fn parse_optional_directive_list(
  tokens: List(Token),
  directives: List(node.DirectiveNode),
) -> Result(
  node.NodeWithTokenList(#(node.Directives, position.Position)),
  ParseError,
) {
  use #(opt_val, tokens) <- result.try(parse_optional_directive(tokens))
  case opt_val {
    Some(val) ->
      parse_optional_directive_list(tokens, list.append(directives, [val]))
    None -> {
      // TODO: This should be passed in as the end positing of the prev character to handle defaults
      use pos <- result.try(
        list.first(tokens)
        |> result.map_error(fn(_e) { errors.EmptyTokenList })
        |> result.map(fn(tkn) { tkn |> pair.second |> pair.second }),
      )
      case directives {
        [] -> Ok(#(#(None, pos), tokens))
        _ -> Ok(#(#(Some(directives), pos), tokens))
      }
    }
  }
}

@internal
pub fn parse_optional_directive(
  tokens: List(Token),
) -> Result(node.NodeWithTokenList(Option(node.DirectiveNode)), ParseError) {
  case tokens {
    [
      #(token_kind.At, #(start, _)),
      #(token_kind.Name(value), location),
      ..tokens
    ] -> {
      use #(#(arguments, end), tokens) <- result.try(parse_optional_args(
        tokens,
        start,
      ))
      Ok(#(
        Some(
          node.DirectiveNode(
            name: node.NameNode(value:, location:),
            arguments:,
            location: #(start, end),
          ),
        ),
        tokens,
      ))
    }
    _ -> Ok(#(None, tokens))
  }
}
