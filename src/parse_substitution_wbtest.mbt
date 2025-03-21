///|
fn assert_str(
  actual : String,
  expected : Array[(String, String)]
) -> Unit!Error {
  let actual_iter = DotenvIter::new(actual)
  let expected_count = expected.length()
  let mut count = 0
  for expected_item in expected {
    let actual_item = actual_iter.next().unwrap().unwrap_or_error!()
    assert_eq!(actual_item, expected_item)
    count += 1
  }
  assert_eq!(count, expected_count)
}

///|
test "variable in parenthesis surrounded by quotes" {
  assert_str!(
    #|KEY=test
    #|KEY1="${KEY}"
    #|
    ,
    [("KEY", "test"), ("KEY1", "test")],
  )
}

///|
test "sub undefined variables to empty string" {
  assert_str!(
    #|KEY=">$KEY1<>${KEY2}<"
    ,
    [("KEY", "><><")],
  )
}

///|
test "do not sub with dollar escaped" {
  assert_str!(
    #|KEY=>\$KEY1<>\${KEY2}<
    ,
    [("KEY", ">$KEY1<>${KEY2}<")],
  )
}

///|
test "do not sub in weak quotes with dollar escaped" {
  assert_str!(
    #|KEY=">\$KEY1<>\${KEY2}<"
    ,
    [("KEY", ">$KEY1<>${KEY2}<")],
  )
}

///|
test "do not sub in strong quotes" {
  assert_str!(
    #|KEY='>${KEY1}<>$KEY2<'
    ,
    [("KEY", ">${KEY1}<>$KEY2<")],
  )
}

///|
test "same variable reused" {
  assert_str!(
    #|KEY=VALUE
    #|KEY1=$KEY$KEY
    #|
    ,
    [("KEY", "VALUE"), ("KEY1", "VALUEVALUE")],
  )
}

///|
test "with dot" {
  assert_str!(
    #|KEY.Value=VALUE
    #|
    ,
    [("KEY.Value", "VALUE")],
  )
}

///|
test "recursive substitution" {
  assert_str!(
    #|KEY=${KEY1}+KEY_VALUE
    #|KEY1=${KEY}+KEY1_VALUE
    #|
    ,
    [("KEY", "+KEY_VALUE"), ("KEY1", "+KEY_VALUE+KEY1_VALUE")],
  )
}

///|
test "var without paranthesis subbed before separators" {
  assert_str!(
    #|KEY1=test_user
    #|KEY1_1=test_user_with_separator
    #|KEY=">$KEY1_1<>$KEY1}<>$KEY1{<"
    #|
    ,
    [
      ("KEY1", "test_user"),
      ("KEY1_1", "test_user_with_separator"),
      ("KEY", ">test_user_1<>test_user}<>test_user{<"),
    ],
  )
}

///|
test "sub var from env var" {
  temp_env!({ "KEY11": "test_user_env" }, fn() {
    assert_str!(
      #|KEY=">${KEY11}<"
      ,
      [("KEY", ">test_user_env<")],
    )
  })
}

///|
test "substitute variable env variable overrides dotenv in substitution" {
  temp_env!({ "KEY11": "test_user_env" }, fn() {
    assert_str!(
      #|KEY11=test_user
      #|KEY=">${KEY11}<"
      #|
      ,
      [("KEY11", "test_user"), ("KEY", ">test_user_env<")],
    )
  })
}

///|
test "consequent substitutions" {
  assert_str!(
    #|KEY1=test_user
    #|KEY2=$KEY1_2
    #|KEY=>${KEY1}<>${KEY2}<
    #|
    ,
    [
      ("KEY1", "test_user"),
      ("KEY2", "test_user_2"),
      ("KEY", ">test_user<>test_user_2<"),
    ],
  )
}

///|
test "consequent substitutions with one missing" {
  assert_str!(
    #|KEY2=$KEY1_2
    #|KEY=>${KEY1}<>${KEY2}<
    #|
    ,
    [("KEY2", "_2"), ("KEY", "><>_2<")],
  )
}
