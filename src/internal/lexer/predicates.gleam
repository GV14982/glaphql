/// Returns `True` if the character is considered ignored whitespace or comment in GraphQL.
///
/// ## Arguments
/// - `char`: The character to check
///
/// ## Returns
/// - `True` if the character is whitespace, comma, or comment marker; otherwise `False`
pub fn is_ignored(char: String) -> Bool {
  case char {
    " " | "\t" | "\n" | "\r" | "," | "#" -> True
    _ -> False
  }
}

/// Returns `True` if the character is valid in a GraphQL name (alphanumeric or underscore).
///
/// ## Arguments
/// - `char`: The character to check
///
/// ## Returns
/// - `True` if the character is valid in a name; otherwise `False`
pub fn is_name(char: String) -> Bool {
  is_alphanumeric(char) || char == "_"
}

/// Returns `True` if the character is valid as the start of a GraphQL name (alpha or underscore).
///
/// ## Arguments
/// - `char`: The character to check
///
/// ## Returns
/// - `True` if the character is valid as a name start; otherwise `False`
pub fn is_name_start(char: String) -> Bool {
  is_alpha(char) || char == "_"
}

/// Returns `True` if the character is alphanumeric (A-Z, a-z, 0-9).
///
/// ## Arguments
/// - `char`: The character to check
///
/// ## Returns
/// - `True` if the character is alphanumeric; otherwise `False`
pub fn is_alphanumeric(char: String) -> Bool {
  is_upper(char) || is_lower(char) || is_digit(char)
}

/// Returns `True` if the character is a digit (0-9).
///
/// ## Arguments
/// - `char`: The character to check
///
/// ## Returns
/// - `True` if the character is a digit; otherwise `False`
pub fn is_digit(char: String) -> Bool {
  char == "0" || is_non_zero_digit(char)
}

/// Returns `True` if the character is a non-zero digit (1-9).
///
/// ## Arguments
/// - `char`: The character to check
///
/// ## Returns
/// - `True` if the character is a non-zero digit; otherwise `False`
pub fn is_non_zero_digit(char: String) -> Bool {
  case char {
    "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    _ -> False
  }
}

/// Returns `True` if the character is an alphabetic letter (A-Z, a-z).
///
/// ## Arguments
/// - `char`: The character to check
///
/// ## Returns
/// - `True` if the character is alphabetic; otherwise `False`
pub fn is_alpha(char: String) -> Bool {
  is_upper(char) || is_lower(char)
}

/// Returns `True` if the character is an uppercase letter (A-Z).
///
/// ## Arguments
/// - `char`: The character to check
///
/// ## Returns
/// - `True` if the character is uppercase; otherwise `False`
pub fn is_upper(char: String) -> Bool {
  case char {
    "A"
    | "B"
    | "C"
    | "D"
    | "E"
    | "F"
    | "G"
    | "H"
    | "I"
    | "J"
    | "K"
    | "L"
    | "M"
    | "N"
    | "O"
    | "P"
    | "Q"
    | "R"
    | "S"
    | "T"
    | "U"
    | "V"
    | "W"
    | "X"
    | "Y"
    | "Z" -> True
    _ -> False
  }
}

pub fn is_lower(char: String) -> Bool {
  case char {
    "a"
    | "b"
    | "c"
    | "d"
    | "e"
    | "f"
    | "g"
    | "h"
    | "i"
    | "j"
    | "k"
    | "l"
    | "m"
    | "n"
    | "o"
    | "p"
    | "q"
    | "r"
    | "s"
    | "t"
    | "u"
    | "v"
    | "w"
    | "x"
    | "y"
    | "z" -> True
    _ -> False
  }
}
