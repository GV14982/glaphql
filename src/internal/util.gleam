import internal/parser/node

pub fn operation_type_to_string(op: node.OperationType) {
  case op {
    node.Query -> "Query"
    node.Mutation -> "Mutation"
    node.Subscription -> "Subscription"
  }
}
