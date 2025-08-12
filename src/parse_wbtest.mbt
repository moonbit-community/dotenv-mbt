///|
test "parse line env" {
  // Note 5 spaces after 'KEY8=' below
  let actual_iter = DotenvIter::new(
    (
      #|KEY=1
      #|KEY2="2"
      #|KEY3='3'
      #|KEY4='fo ur'
      #|KEY5="fi ve"
      #|KEY6=s\ ix
      #|KEY7=
      #|KEY8=     
      #|KEY9=   # foo
      #|KEY10  ="whitespace before ="
      #|KEY11=    "whitespace after ="
      #|export="export as key"
      #|export   SHELL_LOVER=1
    ),
  )
  let expected_iter = [
    ("KEY", "1"),
    ("KEY2", "2"),
    ("KEY3", "3"),
    ("KEY4", "fo ur"),
    ("KEY5", "fi ve"),
    ("KEY6", "s ix"),
    ("KEY7", ""),
    ("KEY8", ""),
    ("KEY9", ""),
    ("KEY10", "whitespace before ="),
    ("KEY11", "whitespace after ="),
    ("export", "export as key"),
    ("SHELL_LOVER", "1"),
  ]
  let actual_parsed = []
  for {
    match actual_iter.next() {
      Some(i) => actual_parsed.push(i.unwrap_or_error())
      None => break
    }
  }
  assert_eq(actual_parsed, expected_iter)
}

///|
test "parse line comment" {
  let input =
    #|# foo=bar
    #|#    
  let result = DotenvIter::new(input)
  let parsed = []
  for {
    match result.next() {
      Some(i) => parsed.push(i.unwrap_or_error())
      None => break
    }
  }
  assert_eq(parsed, [])
}

///|
test "parse line invalid" {
  // Note 4 spaces after 'invalid' below
  let actual_iter = DotenvIter::new(
    (
      #|  invalid    
      #|very bacon = yes indeed
      #|=value
    ),
  )
  let mut count = 0
  for {
    match actual_iter.next() {
      Some(i) => {
        count += 1
        assert_true(i.is_err())
      }
      None => break
    }
  }
  assert_eq(count, 3)
}

///|
test "parse value escapes" {
  let actual_iter = DotenvIter::new(
    (
      #|KEY=my\ cool\ value
      #|KEY2=\$sweet
      #|KEY3="awesome stuff \"mang\""
      #|KEY4='sweet $\fgs'\''fds'
      #|KEY5="'\"yay\\"\ "stuff"
      #|KEY6="lol" #well you see when I say lol wh
      #|KEY7="line 1\nline 2"
    ),
  )
  let expected = [
    ("KEY", "my cool value"),
    ("KEY2", "$sweet"),
    ("KEY3", "awesome stuff \"mang\""),
    ("KEY4", "sweet $\\fgs'fds"),
    ("KEY5", "\'\"yay\\ stuff"),
    ("KEY6", "lol"),
    ("KEY7", "line 1\nline 2"),
  ]
  let actual_parsed = []
  for {
    match actual_iter.next() {
      Some(i) => actual_parsed.push(i.unwrap_or_error())
      None => break
    }
  }
  assert_eq(actual_parsed, expected)
}

///|
test "parse value escapes invalid" {
  let actual_iter = DotenvIter::new(
    (
      #|KEY=my uncool value
      #|KEY2="why
      #|KEY3='please stop''
      #|KEY4=h\8u
      #|
    ),
  )
  for {
    match actual_iter.next() {
      Some(i) => assert_true(i.is_err())
      None => break
    }
  }
}
