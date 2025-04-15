///|
fn parse_line(
  line : String,
  substitution_data : @hashmap.T[String, String?]
) -> (String, String)?!ParseBufError {
  let parser = LineParser::new(line, substitution_data)
  parser.parse_line!()
}

///|
priv struct LineParser {
  original_line : String
  substitution_data : @hashmap.T[String, String?]
  mut line : String
  mut pos : UInt
}

///|
fn LineParser::new(
  line : String,
  substitution_data : @hashmap.T[String, String?]
) -> LineParser {
  {
    original_line: line,
    substitution_data,
    line: line.trim_space(), // we don’t want trailing whitespace
    pos: 0,
  }
}

///|
fn LineParser::err(self : LineParser) -> ParseBufError {
  ParseBufError::LineParse(self.original_line, self.pos)
}

///|
fn LineParser::parse_line(self : LineParser) -> (String, String)?!ParseBufError {
  self.skip_whitespace()
  // if its an empty line or a comment, skip it
  if self.line.is_empty() || self.line.starts_with("#") {
    return None
  }
  let mut key = self.parse_key!()
  self.skip_whitespace()

  // export can be either an optional prefix or a key itself
  if key == "export" {
    // here we check for an optional `=`, below we throw directly when it’s not found.
    if self.expect_equal().is_err() {
      key = self.parse_key!()
      self.skip_whitespace()
      self.expect_equal().unwrap_or_error!()
    }
  } else {
    self.expect_equal().unwrap_or_error!()
  }
  self.skip_whitespace()
  if self.line.is_empty() || self.line.starts_with("#") {
    self.substitution_data[key] = None
    return Some((key, ""))
  }
  let parsed_value = parse_value!(self.line, self.substitution_data)
  self.substitution_data[key] = Some(parsed_value)
  Some((key, parsed_value))
}

///|
fn LineParser::parse_key(self : LineParser) -> String!ParseBufError {
  fn string_starts_with(src : String, predicate : (Char) -> Bool) -> Bool {
    if src.length() == 0 {
      return false
    }
    predicate(src[0])
  }

  fn string_find(src : String, predicate : (Char) -> Bool) -> UInt? {
    let mut index = 0U
    while index < src.length().reinterpret_as_uint() {
      if predicate(src[index.reinterpret_as_int()]) {
        return Some(index)
      }
      index += 1
    }
    None
  }

  if not(
      string_starts_with(self.line, fn(c) {
        c.is_ascii_alphabetic() || c == '_'
      }),
    ) {
    raise self.err()
  }
  let index = match
    string_find(self.line, fn(c) {
      not(c.is_ascii_alphabetic() || c.is_numeric() || c == '_' || c == '.')
    }) {
    Some(index) => index
    None => self.line.length().reinterpret_as_uint()
  }
  self.pos += index
  let key = self.line.substring(start=0, end=index.reinterpret_as_int())
  self.line = self.line.substring(start=index.reinterpret_as_int())
  key
}

///|
fn LineParser::expect_equal(self : LineParser) -> Result[Unit, ParseBufError] {
  if not(self.line.starts_with("=")) {
    return Err(self.err())
  }
  self.line = self.line.substring(start=1)
  self.pos += 1
  Ok(())
}

///|
fn LineParser::skip_whitespace(self : LineParser) -> Unit {
  let mut first_space = 0
  while first_space < self.line.length() {
    if not(self.line[first_space].is_whitespace()) {
      break
    }
    first_space += 1
  }
  if first_space == self.line.length() {
    self.line = ""
  } else {
    self.line = self.line.substring(start=first_space)
  }
}

///|
priv enum SubstitutionMode {
  None
  Block
  EscapedBlock
} derive(Eq)

///|
fn parse_value(
  input : String,
  substitution_data : @hashmap.T[String, String?]
) -> String!ParseBufError {
  // '
  let mut strong_quote = false
  // "
  let mut weak_quote = false
  let mut escaped = false
  let mut expecting_end = false

  //FIXME (from Rust) can this be done without yet another allocation per line?
  let output = StringBuilder::new()
  let mut substitution_mode = SubstitutionMode::None
  let substitution_name = StringBuilder::new()
  for index, c in input.iter2() {
    //the regex _should_ already trim whitespace off the end
    //expecting_end is meant to permit: k=v #comment
    //without affecting: k=v#comment
    //and throwing on: k=v w
    if expecting_end {
      if c == ' ' || c == '\t' {
        continue
      } else if c == '#' {
        break
      }
      raise ParseBufError::LineParse(input, index.reinterpret_as_uint())
    } else if escaped {
      //TODO (from Rust) I tried handling literal \r but various issues
      //imo not worth worrying about until there's a use case
      //(actually handling backslash 0x10 would be a whole other matter)
      //then there's \v \f bell hex... etc
      match c {
        '\\' | '\'' | '"' | '$' | ' ' => output.write_char(c)
        // handle \n case
        'n' => output.write_char('\n')
        _ => raise ParseBufError::LineParse(input, index.reinterpret_as_uint())
      }
      escaped = false
    } else if strong_quote {
      if c == '\'' {
        strong_quote = false
      } else {
        output.write_char(c)
      }
    } else if substitution_mode != SubstitutionMode::None {
      if c.is_ascii_alphabetic() || c.is_numeric() {
        substitution_name.write_char(c)
      } else {
        match substitution_mode {
          SubstitutionMode::None => abort("unreachable")
          SubstitutionMode::Block =>
            if c == '{' && substitution_name.is_empty() {
              substitution_mode = SubstitutionMode::EscapedBlock
            } else {
              apply_substitution(
                substitution_data,
                substitution_name.to_string(),
                output,
              )
              substitution_name.reset()
              if c == '$' {
                substitution_mode = if not(strong_quote) && not(escaped) {
                  SubstitutionMode::Block
                } else {
                  SubstitutionMode::None
                }
              } else {
                substitution_mode = SubstitutionMode::None
                output.write_char(c)
              }
            }
          SubstitutionMode::EscapedBlock =>
            if c == '}' {
              substitution_mode = SubstitutionMode::None
              apply_substitution(
                substitution_data,
                substitution_name.to_string(),
                output,
              )
              substitution_name.reset()
            } else {
              substitution_name.write_char(c)
            }
        }
      }
    } else if c == '$' {
      substitution_mode = if not(strong_quote) && not(escaped) {
        SubstitutionMode::Block
      } else {
        SubstitutionMode::None
      }
    } else if weak_quote {
      if c == '"' {
        weak_quote = false
      } else if c == '\\' {
        escaped = true
      } else {
        output.write_char(c)
      }
    } else if c == '\'' {
      strong_quote = true
    } else if c == '"' {
      weak_quote = true
    } else if c == '\\' {
      escaped = true
    } else if c == ' ' || c == '\t' {
      expecting_end = true
    } else {
      output.write_char(c)
    }
  }

  //XXX also fail if escaped? or...
  if substitution_mode == SubstitutionMode::EscapedBlock ||
    strong_quote ||
    weak_quote {
    let value_length = input.length()
    raise ParseBufError::LineParse(
      input,
      if value_length == 0 {
        0U
      } else {
        (value_length - 1).reinterpret_as_uint()
      },
    )
  } else {
    apply_substitution(substitution_data, substitution_name.to_string(), output)
    substitution_name.reset()
    output.to_string()
  }
}

///|
fn apply_substitution(
  substitution_data : @hashmap.T[String, String?],
  substitution_name : String,
  output : StringBuilder
) -> Unit {
  let env_vars = @sys.get_env_vars()
  if env_vars.contains(substitution_name) {
    output.write_string(env_vars[substitution_name].unwrap())
  } else {
    let stored_value = substitution_data[substitution_name].or(None)
    output.write_string(stored_value.or_default())
  }
}
