import internal/parser/node

/// Converts a GraphQL OperationType to its string representation.
///
/// ## Arguments
/// - `op`: The operation type (Query, Mutation, Subscription)
///
/// ## Returns
/// - The string name of the operation type
pub fn operation_type_to_string(op: node.OperationType) {
  case op {
    node.Query -> "Query"
    node.Mutation -> "Mutation"
    node.Subscription -> "Subscription"
  }
}
