import errors.{type ParseError}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import lexer/position
import lexer/token.{type Token}
import lexer/token_kind
import parser/const_arg_def.{parse_optional_const_arg_defs}
import parser/node

@internal
pub fn parse_optional_const_directive_list(
  tokens: List(Token),
  directives: List(node.ConstDirectiveNode),
) -> Result(
  node.NodeWithTokenList(#(node.ConstDirectives, position.Position)),
  ParseError,
) {
  use #(opt_val, tokens) <- result.try(parse_optional_const_directive(tokens))
  case opt_val {
    Some(val) ->
      parse_optional_const_directive_list(tokens, [val, ..directives])
    None -> {
      // TODO: This should be passed in as the end positing of the prev character to handle defaults
      use pos <- result.try(
        list.first(tokens)
        |> result.map_error(fn(_e) { errors.EmptyTokenList })
        |> result.map(fn(tkn) { tkn |> pair.second |> pair.second }),
      )
      case directives {
        [] -> Ok(#(#(None, pos), tokens))
        _ -> Ok(#(#(Some(directives |> list.reverse), pos), tokens))
      }
    }
  }
}

@internal
pub fn parse_optional_const_directive(
  tokens: List(Token),
) -> Result(node.NodeWithTokenList(Option(node.ConstDirectiveNode)), ParseError) {
  case tokens {
    [#(token_kind.At, start), #(token_kind.Name(name), name_loc), ..tokens] -> {
      use #(#(arguments, end), tokens) <- result.try(
        parse_optional_const_arg_defs(tokens),
      )
      Ok(#(
        Some(
          node.ConstDirectiveNode(
            name: node.NameNode(value: name, location: name_loc),
            arguments:,
            location: #(start.0, end),
          ),
        ),
        tokens,
      ))
    }
    _ -> Ok(#(None, tokens))
  }
}
