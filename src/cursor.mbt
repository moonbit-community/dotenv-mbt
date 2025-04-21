///|
priv struct Cursor {
  data : String
  /// The current position in the data
  mut pos : UInt64
}

///|
fn Cursor::new(data : String) -> Cursor {
  { data, pos: 0 }
}

///|
fn Cursor::read_line(self : Cursor) -> String {
  if self.peek().is_empty() {
    return ""
  }
  let result = StringBuilder::new()
  while true {
    guard self.next() is Some(byte) else {
      result.write_char('\n')
      break
    }
    if byte == '\n'.to_int() {
      result.write_char('\n')
      break
    }
    if byte == '\r'.to_int() {
      // Check if the next byte is a newline(CRLF)
      let next = self.peek()
      if next == Some('\n') {
        // Skip the newline byte
        ignore(self.next())
      }
      result.write_char('\n')
      break
    }
    result.write_char(Char::from_int(byte))
  }
  // Convert the result to a string
  result.to_string()
}

///|
fn Cursor::length(self : Cursor) -> UInt64 {
  self.data.length().to_uint64()
}

///|
fn Cursor::next(self : Cursor) -> Int? {
  if self.pos >= self.data.length().to_uint64() {
    None
  } else {
    let char = self.data.charcode_at(self.pos.to_int())
    self.pos += 1
    Some(char)
  }
}

///|
fn Cursor::peek(self : Cursor) -> Int? {
  if self.pos >= self.data.length().to_uint64() {
    None
  } else {
    Some(self.data.charcode_at(self.pos.to_int()))
  }
}

///|
fn Cursor::pos(self : Cursor) -> UInt64 {
  self.pos
}

///|
fn Cursor::set_pos(self : Cursor, pos : UInt64) -> Unit {
  self.pos = pos
}

///|
fn Cursor::next_line(self : Cursor) -> Result[String, ParseBufError]? {
  for {
    let mut buf = ""
    let mut cur_state = ParseState::Complete
    let mut buf_pos : UInt = 0
    let mut cur_pos : UInt = 0
    for {
      buf_pos = buf.length().reinterpret_as_uint()
      let new_line = self.read_line()
      buf = buf + new_line
      match new_line {
        "" => {
          // End of file
          if cur_state == ParseState::Complete {
            return None
          }
          let len = buf.length()
          return Some(
            Err(ParseBufError::LineParse(buf, len.reinterpret_as_uint())),
          )
        }
        _ => {
          // Skip lines which start with a `#` before iteration
          // This optimizes parsing a bit.
          if buf.trim_space().to_string().has_prefix("#") {
            return Some(Ok(""))
          }
          let result = cur_state.eval_end(
            buf.view(start_offset=buf_pos.reinterpret_as_int()).to_string(),
          )
          cur_pos = result.0
          cur_state = result.1
          match cur_state {
            ParseState::Complete =>
              return Some(
                Ok(
                  // TODO: Performance optimization
                  buf.trim_end("\n").trim_end("\r").to_string(),
                ),
              )
            ParseState::Escape
            | ParseState::StrongOpen
            | ParseState::StrongOpenEscape
            | ParseState::WeakOpen
            | ParseState::WeakOpenEscape
            | ParseState::WhiteSpace => ()
            ParseState::Comment =>
              return Some(
                Ok(
                  buf
                  .view(
                    start_offset=0,
                    end_offset=(buf_pos + cur_pos).reinterpret_as_int(),
                  )
                  .to_string(),
                ),
              )
          }
        }
      }
    }
  }
}
