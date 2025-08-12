// TODO: port error_tests

///|
test "should not parse unfinished subs" {
  let invalid_value = ">${baz{<"
  let iter = DotenvIter::new(
    (
      #|FOO=bar
      #|BAR={invalid_value}
    ).replace(old="{invalid_value}", new=invalid_value),
  )
  let parsed : Array[Result[(String, String), ParseBufError]] = Array::new()
  for {
    match iter.next() {
      Some(line) => parsed.push(line)
      None => break
    }
  }

  // first line works
  assert_eq(parsed[0].unwrap(), ("FOO", "bar"))
  // second line error
  match parsed[1] {
    Err(ParseBufError::LineParse(v, idx)) if v == invalid_value &&
      idx == (invalid_value.length() - 1).reinterpret_as_uint() => ()
    _ => abort("Expected error for invalid value")
  }
}

///|
test "should not allow dot as first char of key" {
  let invalid_key = ".KEY=value"
  let iter = DotenvIter::new(invalid_key)
  let parsed : Array[Result[(String, String), ParseBufError]] = Array::new()
  for {
    match iter.next() {
      Some(line) => parsed.push(line)
      None => break
    }
  }
  match parsed[0] {
    Err(ParseBufError::LineParse(v, idx)) if v == invalid_key && idx == 0U => ()
    _ => abort("Expected error for invalid key")
  }
}

///|
test "should not parse invalid format" {
  let invalid_fmt = "<><><>"
  let iter = DotenvIter::new(invalid_fmt)
  let parsed : Array[Result[(String, String), ParseBufError]] = Array::new()
  for {
    match iter.next() {
      Some(line) => parsed.push(line)
      None => break
    }
  }
  match parsed[0] {
    Err(ParseBufError::LineParse(v, idx)) if v == invalid_fmt && idx == 0U => ()
    _ => abort("Expected error for invalid format")
  }
}

///|
test "should not parse invalid escape" {
  let invalid_esc = ">\\f<"
  let iter = DotenvIter::new("VALUE=\{invalid_esc}")
  let parsed : Array[Result[(String, String), ParseBufError]] = Array::new()
  for {
    match iter.next() {
      Some(line) => parsed.push(line)
      None => break
    }
  }
  match parsed[0] {
    Err(ParseBufError::LineParse(v, idx)) if v == invalid_esc &&
      idx == (invalid_esc.find("\\").unwrap() + 1).reinterpret_as_uint() => ()
    _ => abort("Expected error for invalid escape")
  }
}
