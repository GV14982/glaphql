import errors
import gleam/bool
import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import internal/schema/types

@internal
pub fn check_interface_implementations(
  type_def: types.ExecutableTypeDef,
  type_maps: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(Nil, errors.InterfaceImplementationValidationError) {
  use #(name, interface_names, fields) <- result.try(get_implementable_type(
    type_def,
  ))
  use _ <- result.try(interface_names |> interface_implementation_unique)
  use interfaces <- result.try(names_to_interface_types(
    interface_names,
    type_maps,
  ))
  use parents <- result.try(collect_parent_implementations(
    interface_names,
    type_maps,
  ))
  use _ <- result.try(check_interface_cycles(name, parents))
  use <- bool.guard(
    interfaces |> list.length != parents |> list.length,
    Error(errors.IncompleteInterfaceImplementation(name:)),
  )
  use _ <- result.try(validate_interface_fields(name, fields, interfaces))
  Ok(Nil)
}

fn interface_implementation_unique(
  interfaces: List(String),
) -> Result(Nil, errors.InterfaceImplementationValidationError) {
  let #(_, val) =
    interfaces
    |> list.fold_until(#(set.new(), option.None), fn(acc, curr) {
      let #(existing, _) = acc
      case existing |> set.contains(curr) {
        True -> list.Stop(#(existing, option.Some(curr)))
        False -> list.Continue(#(existing |> set.insert(curr), option.None))
      }
    })
  case val {
    option.Some(name) -> Error(errors.NonUniqueInterfaceList(name:))
    option.None -> Ok(Nil)
  }
}

fn check_interface_cycles(
  name: String,
  interfaces: List(types.ExecutableInterfaceTypeDef),
) -> Result(Nil, errors.InterfaceImplementationValidationError) {
  case interfaces |> list.all(fn(interface) { interface.name != name }) {
    True -> Ok(Nil)
    False -> Error(errors.CyclicInterfaceReference(name:))
  }
}

fn collect_parent_implementations(
  names: List(String),
  type_maps: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(
  List(types.ExecutableInterfaceTypeDef),
  errors.InterfaceImplementationValidationError,
) {
  use interfaces <- result.try(names_to_interface_types(names, type_maps))
  let parent_result =
    interfaces
    |> list.map(fn(interface) {
      collect_parent_implementations(interface.interfaces, type_maps)
      |> result.map(fn(vals) { list.append(vals, interfaces) })
    })
    |> result.all
  use parent_interfaces <- result.try(parent_result)
  parent_interfaces |> list.flatten |> list.unique |> Ok
}

fn names_to_interface_types(
  names: List(String),
  type_maps: dict.Dict(String, types.ExecutableTypeDef),
) -> Result(
  List(types.ExecutableInterfaceTypeDef),
  errors.InterfaceImplementationValidationError,
) {
  names
  |> list.fold_until(Ok([]), fn(acc, name) {
    case type_maps |> dict.get(name) {
      Ok(types.InterfaceTypeDef(val)) ->
        list.Continue(acc |> result.map(fn(interfaces) { [val, ..interfaces] }))
      Ok(_) -> list.Stop(Error(errors.ImplementsNonInterface(name:)))
      Error(_) -> list.Stop(Error(errors.UndefinedInterface(name:)))
    }
  })
  |> result.map(list.reverse)
}

fn validate_interface_fields(
  name: String,
  fields: dict.Dict(String, types.ExecutableFieldDef),
  interfaces: List(types.ExecutableInterfaceTypeDef),
) -> Result(Nil, errors.InterfaceImplementationValidationError) {
  let interface_fields =
    interfaces
    |> list.flat_map(fn(interface) { interface.fields |> dict.to_list })
  let implemented_fields_result =
    interface_fields
    |> list.fold_until(Ok([]), fn(acc, curr) {
      let #(this_name, this_field) = curr
      case fields |> dict.get(this_name) {
        Ok(types.ExecutableFieldDef(
          description: _,
          directives: _,
          name: _,
          named_type:,
          args:,
        )) ->
          case named_type == this_field.named_type && args == this_field.args {
            True ->
              list.Continue(acc |> result.map(fn(vals) { [curr, ..vals] }))
            False ->
              list.Stop(
                Error(errors.IncorrectFieldType(
                  name:,
                  field: this_name,
                  found_type: named_type,
                  expected_type: this_field.named_type,
                )),
              )
          }
        _ -> list.Continue(acc)
      }
    })
  use implemented_fields <- result.try(implemented_fields_result)
  use <- bool.guard(
    interface_fields |> list.length == implemented_fields |> list.length,
    Ok(Nil),
  )
  Error(errors.MissingFields(
    name:,
    fields: interface_fields |> list.map(fn(tuple) { tuple.0 }),
  ))
}

fn get_implementable_type(
  type_def: types.ExecutableTypeDef,
) -> Result(
  #(String, List(String), dict.Dict(String, types.ExecutableFieldDef)),
  errors.InterfaceImplementationValidationError,
) {
  case type_def {
    types.ObjectTypeDef(types.ExecutableObjectTypeDef(
      description: _,
      directives: _,
      interfaces:,
      name:,
      fields:,
    ))
    | types.InterfaceTypeDef(types.ExecutableInterfaceTypeDef(
        description: _,
        directives: _,
        interfaces:,
        name:,
        fields:,
      )) -> {
      Ok(#(name, interfaces, fields))
    }
    types.EnumTypeDef(types.ExecutableEnumTypeDef(
      description: _,
      directives: _,
      members: _,
      name:,
    ))
    | types.InputTypeDef(types.ExecutableInputTypeDef(
        description: _,
        directives: _,
        fields: _,
        name:,
      ))
    | types.ScalarTypeDef(types.ExecutableScalarTypeDef(
        description: _,
        directives: _,
        name:,
      ))
    | types.UnionTypeDef(types.ExecutableUnionTypeDef(
        description: _,
        directives: _,
        members: _,
        name:,
      )) -> Error(errors.ImplementsNonInterface(name: name))
  }
}
