import internal/executable/types

pub fn is_nullable(named_type: types.ExecutableType) -> Bool {
  case named_type {
    types.ListType(val) -> val.nullable
    types.NamedType(val) -> val.nullable
  }
}
