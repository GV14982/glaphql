pub type TokenKind {
  // End of File
  EOF
  // !
  Bang
  // ?
  Question
  // $
  Dollar
  // &
  Amp
  // :
  Colon
  // =
  Equal
  // @
  At
  // |
  Pipe
  // ...
  Spread
  // (
  OpenParen
  // )
  CloseParen
  // [
  OpenBracket
  // ]
  CloseBracket
  // {
  OpenBrace
  // }
  CloseBrace
  // Name
  Name(String)
  // String Literal
  String(String)
  // Integer Literal
  Int(String)
  // Floating Point Number Literal
  Float(String)
  // Comment starting with a #
  Comment(String)
}
