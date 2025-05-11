import errors
import gleam/list
import gleam/option
import gleam/pair
import gleam/result
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/const_arg_def
import internal/parser/node

pub fn parse_optional_const_directive_list(
  tokens: List(token.Token),
  directives: List(node.ConstDirectiveNode),
) -> Result(
  node.NodeWithTokenList(#(node.ConstDirectives, position.Position)),
  errors.ParseError,
) {
  use #(opt_val, tokens) <- result.try(parse_optional_const_directive(tokens))
  case opt_val {
    option.Some(val) ->
      parse_optional_const_directive_list(tokens, [val, ..directives])
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

pub fn parse_optional_const_directive(
  tokens: List(token.Token),
) -> Result(
  node.NodeWithTokenList(option.Option(node.ConstDirectiveNode)),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.At, start), #(token_kind.Name(name), name_loc), ..tokens] -> {
      use #(#(arguments, end), tokens) <- result.try(
        const_arg_def.parse_optional_const_arg_defs(tokens),
      )
      Ok(#(
        option.Some(
          node.ConstDirectiveNode(
            name: node.NameNode(value: name, location: name_loc),
            arguments:,
            location: #(start.0, end),
          ),
        ),
        tokens,
      ))
    }
    _ -> Ok(#(option.None, tokens))
  }
}
