import errors
import gleam/option
import gleam/result
import internal/lexer/position
import internal/lexer/token
import internal/lexer/token_kind
import internal/parser/node
import internal/parser/schema/directive_def
import internal/parser/schema/enum
import internal/parser/schema/input_def
import internal/parser/schema/interface
import internal/parser/schema/object_def
import internal/parser/schema/scalar
import internal/parser/schema/schema_def
import internal/parser/schema/union

pub fn parse(
  tokens: List(token.Token),
  description: option.Option(node.DescriptionNode),
) -> Result(
  node.NodeWithTokenList(node.TypeSystemDefinitionOrExtensionNode),
  errors.ParseError,
) {
  case tokens {
    [#(token_kind.Name("schema"), #(start, _)), ..tokens] -> {
      use #(schema, tokens) <- result.try(schema_def.parse_schema_definition(
        tokens,
        description,
        start,
      ))
      Ok(#(node.TypeSystemDefinitionNode(node: schema), tokens))
    }
    [#(token_kind.Name("directive"), #(start, _)), ..tokens] -> {
      use #(directive, tokens) <- result.try(directive_def.parse_directive_def(
        tokens,
        description,
        start,
      ))
      Ok(#(node.TypeSystemDefinitionNode(node: directive), tokens))
    }
    [#(token_kind.Name("extend"), #(start, _)), ..tokens] -> {
      case tokens {
        [#(token_kind.Name(val), _), ..tokens] -> {
          case val {
            "type" | "enum" | "scalar" | "interface" | "union" | "input" -> {
              use #(node, tokens) <- result.try(parse_type_ext(
                val,
                tokens,
                start,
              ))
              Ok(#(
                node.TypeSystemExtensionNode(node: node.TypeExtensionNode(node:)),
                tokens,
              ))
            }
            "schema" -> {
              use #(node, tokens) <- result.try(
                schema_def.parse_schema_extension(tokens, start),
              )
              Ok(#(node.TypeSystemExtensionNode(node:), tokens))
            }
            _ -> Error(errors.InvalidTypeSystemExtension)
          }
        }
        _ -> Error(errors.InvalidTypeSystemExtension)
      }
    }
    [#(token_kind.Name(val), #(start, _)), ..tokens] -> {
      use #(typedef, tokens) <- result.try(parse_type_def(
        val,
        tokens,
        description,
        start,
      ))
      Ok(#(
        node.TypeSystemDefinitionNode(node: node.TypeDefinitionNode(
          node: typedef,
        )),
        tokens,
      ))
    }
    _ -> Error(errors.InvalidTypeSystemDefinition)
  }
}

pub fn parse_type_ext(
  name: String,
  tokens: List(token.Token),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeExtensionNode), errors.ParseError) {
  case name {
    // Type exts
    "type" -> object_def.parse_object_ext(tokens, start)
    "enum" -> enum.parse_enum_ext(tokens, start)
    "scalar" -> scalar.parse_scalar_ext(tokens, start)
    "interface" -> interface.parse_interface_ext(tokens, start)
    "union" -> union.parse_union_ext(tokens, start)
    "input" -> input_def.parse_input_ext(tokens, start)
    // Handle error
    _ -> Error(errors.InvalidTypeSystemExtension)
  }
}

pub fn parse_type_def(
  name: String,
  tokens: List(token.Token),
  description: option.Option(node.DescriptionNode),
  start: position.Position,
) -> Result(node.NodeWithTokenList(node.TypeDefinitionNode), errors.ParseError) {
  case name {
    // Type defs
    "type" -> object_def.parse_object_def(tokens, description, start)
    "enum" -> enum.parse_enum_def(tokens, description, start)
    "scalar" -> scalar.parse_scalar_def(tokens, description, start)
    "interface" -> interface.parse_interface_def(tokens, description, start)
    "union" -> union.parse_union_def(tokens, description, start)
    "input" -> input_def.parse_input_def(tokens, description, start)
    // Handle error
    _ -> Error(errors.InvalidTypeSystemDefinition)
  }
}
