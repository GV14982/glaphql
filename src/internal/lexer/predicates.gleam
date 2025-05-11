pub fn is_ignored(char: String) -> Bool {
  case char {
    " " | "\t" | "\n" | "\r" | "," | "#" -> True
    _ -> False
  }
}

pub fn is_name(char: String) -> Bool {
  is_alphanumeric(char) || char == "_"
}

pub fn is_name_start(char: String) -> Bool {
  is_alpha(char) || char == "_"
}

pub fn is_alphanumeric(char: String) -> Bool {
  is_upper(char) || is_lower(char) || is_digit(char)
}

pub fn is_digit(char: String) -> Bool {
  char == "0" || is_non_zero_digit(char)
}

pub fn is_non_zero_digit(char: String) -> Bool {
  case char {
    "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    _ -> False
  }
}

pub fn is_alpha(char: String) -> Bool {
  is_upper(char) || is_lower(char)
}

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
