///|
priv struct DotenvIter {
  cursor : Cursor
  substitution_data : @hashmap.T[String, String?]
}

///|
fn DotenvIter::new(data : String) -> DotenvIter {
  let cursor = Cursor::new(data)
  { cursor, substitution_data: @hashmap.new() }
}

///|
fn DotenvIter::internal_load(
  self : DotenvIter,
  load_fn : (String, String, EnvMap) -> Unit,
) -> EnvMap raise ParseBufError {
  self.remove_bom()
  let map = EnvMap::new()
  for {
    let item = self.next()
    if item.is_empty() {
      break
    }
    let item = item.unwrap().unwrap_or_error()
    let (k, v) = item
    load_fn(k, v, map)
  }
  map
}

///|
fn DotenvIter::load(self : DotenvIter) -> EnvMap raise ParseBufError {
  self.internal_load(fn(k, v, map) { map.map[k] = v })
}

///|
fn DotenvIter::load_and_modify(self : DotenvIter) -> EnvMap raise ParseBufError {
  // Not thread-safe
  let vars = @sys.get_env_vars()
  self.internal_load(fn(k, v, map) {
    if not(vars.contains(k)) {
      @sys.set_env_var(k, v)
    }
    map.map[k] = v
  })
}

///|
fn DotenvIter::load_and_modify_override(
  self : DotenvIter,
) -> EnvMap raise ParseBufError {
  self.internal_load(fn(k, v, map) {
    @sys.set_env_var(k, v)
    map.map[k] = v
  })
}

///| Removes the BOM if it exists.
///
/// For more info, see the [Unicode BOM character](https://www.compart.com/en/unicode/U+FEFF).
fn DotenvIter::remove_bom(self : DotenvIter) -> Unit {
  guard self.cursor.length() >= 3 else { return }
  let origin_pos = self.cursor.pos()
  if self.cursor.next() is Some(0xfeff) {
    // The BOM is present, so exit early
    return
  }
  // The BOM is not present, so we reset the cursor position
  self.cursor.set_pos(origin_pos)
}

///|
priv enum ParseState {
  Complete
  Escape
  StrongOpen
  StrongOpenEscape
  WeakOpen
  WeakOpenEscape
  Comment
  WhiteSpace
} derive(Eq)

///|
fn ParseState::eval_end(self : ParseState, buf : String) -> (UInt, ParseState) {
  let mut cur_state = self
  let mut cur_pos : UInt = 0
  for pos, c in buf.iter2() {
    cur_pos = pos.reinterpret_as_uint()
    cur_state = match cur_state {
      ParseState::WhiteSpace =>
        match c {
          '#' => return (cur_pos, ParseState::Comment)
          '\\' => ParseState::Escape
          '"' => ParseState::WeakOpen
          '\'' => ParseState::StrongOpen
          _ => ParseState::Complete
        }
      ParseState::Escape => ParseState::Complete
      ParseState::Complete =>
        match c {
          c if c.is_whitespace() && c != '\n' && c != '\r' =>
            ParseState::WhiteSpace
          '\\' => ParseState::Escape
          '"' => ParseState::WeakOpen
          '\'' => ParseState::StrongOpen
          _ => ParseState::Complete
        }
      ParseState::WeakOpen =>
        match c {
          '\\' => ParseState::WeakOpenEscape
          '"' => ParseState::Complete
          _ => ParseState::WeakOpen
        }
      ParseState::WeakOpenEscape => ParseState::WeakOpen
      ParseState::StrongOpen =>
        match c {
          '\\' => ParseState::StrongOpenEscape
          '\'' => ParseState::Complete
          _ => ParseState::StrongOpen
        }
      ParseState::StrongOpenEscape => ParseState::StrongOpen
      // Comments last the entire line.
      ParseState::Comment => abort("should have returned already")
    }
  }
  (cur_pos, cur_state)
}

///|
fn DotenvIter::next(
  self : DotenvIter,
) -> Result[(String, String), ParseBufError]? {
  for {
    let line = match self.cursor.next_line() {
      Some(Ok(line)) => line
      Some(Err(e)) => return Some(Err(e))
      None => return None
    }
    match (try? parse_line(line, self.substitution_data)) {
      Ok(Some(res)) => return Some(Ok(res))
      Ok(None) => continue
      Err(e) => return Some(Err(e))
    }
  }
}

///|
pub suberror ParseBufError {
  LineParse(String, UInt)
}
