import glam/doc
import gleam/dict
import gleam/dynamic
import gleam/list
import gleam/option
import gleam/result
import internal/executable/types
import justin

type ResolverFn(parent, context) =
  fn(parent, context, Nil) -> dynamic.Dynamic

type Resolvers(parent, context) =
  dict.Dict(String, ResolverFn(parent, context))

fn pub_keyword() -> doc.Document {
  doc.from_string("pub")
}

fn type_keyword() -> doc.Document {
  doc.from_string("type")
}

fn fn_keyword() -> doc.Document {
  doc.from_string("fn")
}

fn arrow() -> doc.Document {
  doc.from_string("->")
}

fn comma() -> doc.Document {
  doc.from_string(",")
}

fn colon() -> doc.Document {
  doc.from_string(":")
}

fn open_peren() -> doc.Document {
  doc.from_string("(")
}

fn close_peren() -> doc.Document {
  doc.from_string(")")
}

fn open_brace() -> doc.Document {
  doc.from_string("{")
}

fn close_brace() -> doc.Document {
  doc.from_string("}")
}

fn open_bracket() -> doc.Document {
  doc.from_string("[")
}

fn close_bracket() -> doc.Document {
  doc.from_string("]")
}

pub type Models {
  Models(
    scalar: doc.Document,
    enum: doc.Document,
    union: doc.Document,
    object: doc.Document,
    input: doc.Document,
  )
}

fn doc_or_concat(
  document: doc.Document,
  opt: option.Option(doc.Document),
  lines: Int,
) -> doc.Document {
  case opt {
    option.None -> document
    option.Some(val) -> doc.concat([val, doc.lines(lines), document])
  }
}

pub fn generate_resolver(obj: types.ExecutableObjectTypeDef) {
  doc.concat([
    pub_keyword(),
    doc.space,
    fn_keyword(),
    doc.space,
    justin.snake_case(obj.name <> "_resolver") |> doc.from_string,
    open_peren(),
    doc.soft_break,
    close_peren(),
    doc.space,
    arrow(),
    doc.space,
    wrap_in_result(
      justin.pascal_case(obj.name) |> doc.from_string,
      doc.from_string("TODO"),
    ),
    doc.space,
    open_brace(),
    doc.soft_break,
    close_brace(),
  ])
  |> doc.group
}

pub fn generate_models(schema: types.ExecutableSchema) -> doc.Document {
  let _ = schema.query.name
  let models =
    schema.type_map
    |> dict.fold(dict.new(), fn(acc, _, val) {
      case val {
        types.EnumTypeDef(enum) -> {
          let document = generate_enum_model(enum)
          acc
          |> dict.upsert("enum", doc_or_concat(document, _, 2))
        }
        types.InputTypeDef(input) -> {
          let document = generate_input_model(input)
          acc
          |> dict.upsert("input", doc_or_concat(document, _, 2))
        }
        types.ObjectTypeDef(object) -> {
          let document = generate_object_model(object)
          acc
          |> dict.upsert("object", doc_or_concat(document, _, 2))
        }
        types.ScalarTypeDef(scalar) -> {
          let document = generate_scalar_model(scalar)
          acc
          |> dict.upsert("scalar", doc_or_concat(document, _, 1))
        }
        types.UnionTypeDef(union) -> {
          let document = generate_union_model(union)
          acc
          |> dict.upsert("union", doc_or_concat(document, _, 2))
        }
        _ -> acc
      }
    })
  doc.concat([
    doc.from_string("// Scalars"),
    doc.line,
    models
      |> dict.get("scalar")
      |> result.map(fn(d) { doc.append(d, doc.lines(2)) })
      |> result.unwrap(doc.empty),
    doc.from_string("// Enums"),
    doc.line,
    models
      |> dict.get("enum")
      |> result.map(fn(d) { doc.append(d, doc.lines(2)) })
      |> result.unwrap(doc.empty),
    doc.from_string("// Unions"),
    doc.line,
    models
      |> dict.get("union")
      |> result.map(fn(d) { doc.append(d, doc.lines(2)) })
      |> result.unwrap(doc.empty),
    doc.from_string("// Inputs"),
    doc.line,
    models
      |> dict.get("input")
      |> result.map(fn(d) { doc.append(d, doc.lines(2)) })
      |> result.unwrap(doc.empty),
    doc.from_string("// Objects"),
    doc.line,
    models
      |> dict.get("object")
      |> result.unwrap(doc.empty),
  ])
}

pub fn generate_union_model(union: types.ExecutableUnionTypeDef) -> doc.Document {
  let name = justin.pascal_case(union.name) |> doc.from_string
  let variants =
    union.members
    |> list.map(fn(member) {
      let member = justin.pascal_case(member) |> doc.from_string
      doc.concat([
        name,
        member,
        open_peren(),
        doc.empty,
        member,
        doc.empty,
        close_peren(),
      ])
    })
  wrap_in_type(name, variants)
}

pub fn generate_scalar_model(
  scalar: types.ExecutableScalarTypeDef,
) -> doc.Document {
  doc.concat([
    type_keyword(),
    doc.space,
    justin.pascal_case(scalar.name) |> doc.from_string,
  ])
}

pub fn generate_enum_model(enum: types.ExecutableEnumTypeDef) -> doc.Document {
  let members =
    enum.members
    |> list.map(fn(member) { doc.from_string(member.name) })
  wrap_in_type(doc.from_string(enum.name), members)
}

pub fn generate_input_model(input: types.ExecutableInputTypeDef) -> doc.Document {
  let args =
    input.fields
    |> dict.values
    |> list.map(fn(val) { generate_field(val.name, val.named_type) })
    |> doc.concat_join([comma(), doc.space])
  let name = doc.from_string(input.name)
  let constructor =
    name
    |> doc.append(
      doc.concat([
        open_peren(),
        doc.concat([
          doc.soft_break |> doc.append(args) |> doc.nest(2),
          doc.soft_break,
        ])
          |> doc.group,
        close_peren(),
      ]),
    )
  name |> wrap_in_type([constructor])
}

pub fn generate_object_model(obj: types.ExecutableObjectTypeDef) -> doc.Document {
  let args =
    obj.fields
    |> dict.values
    |> list.map(fn(val) { generate_field(val.name, val.named_type) })
    |> doc.concat_join([comma(), doc.space])
  let name = doc.from_string(obj.name)
  let constructor =
    name
    |> doc.append(
      doc.concat([
        open_peren(),
        doc.concat([
          doc.soft_break |> doc.append(args) |> doc.nest(2),
          doc.soft_break,
        ])
          |> doc.group,
        close_peren(),
      ]),
    )
  name |> wrap_in_type([constructor])
}

pub fn generate_field(
  name: String,
  named_type: types.ExecutableType,
) -> doc.Document {
  doc.concat([
    doc.from_string(justin.snake_case(name)),
    colon(),
    doc.space,
    generate_type(named_type),
  ])
  |> doc.group
}

pub fn generate_type(exec_type: types.ExecutableType) -> doc.Document {
  case exec_type {
    types.ListType(list_type) ->
      case list_type.nullable {
        False -> generate_type(list_type.executable_type) |> wrap_in_list
        True ->
          generate_type(list_type.executable_type)
          |> wrap_in_list
          |> wrap_in_option
      }
    types.NamedType(named_type) -> {
      let name = justin.pascal_case(named_type.name) |> doc.from_string
      case named_type.nullable {
        False -> name
        True -> wrap_in_option(name)
      }
    }
  }
}

fn wrap_in_list(val: doc.Document) -> doc.Document {
  doc.concat([
    doc.from_string("List"),
    open_peren(),
    doc.empty,
    val,
    doc.empty,
    close_peren(),
  ])
}

fn wrap_in_option(val: doc.Document) -> doc.Document {
  doc.concat([
    doc.from_string("option.Option"),
    open_peren(),
    doc.empty,
    val,
    doc.empty,
    close_peren(),
  ])
}

fn wrap_in_result(left: doc.Document, right: doc.Document) -> doc.Document {
  doc.concat([
    doc.from_string("Result"),
    open_peren(),
    doc.empty,
    left,
    comma(),
    doc.space,
    right,
    doc.empty,
    close_peren(),
  ])
}

fn wrap_in_type(
  name: doc.Document,
  variants: List(doc.Document),
) -> doc.Document {
  doc.concat([
    pub_keyword(),
    doc.space,
    type_keyword(),
    doc.space,
    name,
    doc.space,
    open_brace(),
    doc.nest(doc.concat([doc.line, doc.join(variants, doc.line)]), 2),
    doc.line,
    close_brace(),
  ])
}
