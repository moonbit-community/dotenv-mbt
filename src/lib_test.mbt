///|
test "substitution" {
  @sys.set_env_var("KEY", "value")
  @sys.set_env_var("KEY1", "value1")
  let subs = [
    "$ZZZ", "$KEY", "$KEY1", "${KEY}1", "$KEY_U", "${KEY_U}", "\\$KEY",
  ]
  let common_string = subs.join(">>")
  let s = (
    #|    KEY1=new_value1
    #|    KEY_U=$KEY+valueU
    #|    
    #|    STRONG_QUOTES='{common_string}'
    #|    WEAK_QUOTES="{common_string}"
    #|    NO_QUOTES={common_string}
    #|    
  ).replace_all(old="{common_string}", new=common_string)
  let env_map = EnvLoader::from_string(s)
    .set_sequence(EnvSequence::InputThenEnv)
    .load()
  assert_eq(env_map.get("KEY").unwrap(), "value")
  assert_eq(env_map.get("KEY1").unwrap(), "value1")
  assert_eq(env_map.get("KEY_U").unwrap(), "value+valueU")
  assert_eq(env_map.get("STRONG_QUOTES").unwrap(), common_string)
  assert_eq(
    env_map.get("WEAK_QUOTES").unwrap(),
    ["", "value", "value1", "value1", "value_U", "value+valueU", "$KEY"].join(
      ">>",
    ),
  )
  assert_eq(
    env_map.get("NO_QUOTES").unwrap(),
    ["", "value", "value1", "value1", "value_U", "value+valueU", "$KEY"].join(
      ">>",
    ),
  )
}

///|
test "multiline" {
  let value = "-----BEGIN PRIVATE KEY-----\n-----END PRIVATE KEY-----\\n\\\"QUOTED\\\""
  let weak = "-----BEGIN PRIVATE KEY-----\n-----END PRIVATE KEY-----\n\"QUOTED\""
  let s = (
    #|    KEY=my\ cool\ value
    #|    KEY3="awesome \"stuff\"
    #|    more
    #|    on other
    #|    lines"
    #|    KEY4='hello '\''world'"
    #|    good ' \'morning"
    #|    WEAK="{value}"
    #|    STRONG='{value}'
  ).replace_all(old="{value}", new=value)
  let env_map = EnvLoader::from_string(s)
    .set_sequence(EnvSequence::InputOnly)
    .load()
  assert_eq(env_map.get("KEY").unwrap(), "my cool value")
  assert_eq(
    env_map.get("KEY3").unwrap(),
    (
      #|awesome "stuff"
      #|    more
      #|    on other
      #|    lines
    ),
  )
  assert_eq(env_map.get("KEY4").unwrap(), "hello 'world\n    good ' 'morning")
  assert_eq(env_map.get("WEAK").unwrap(), weak)
  assert_eq(env_map.get("STRONG").unwrap(), value)
}

///|
test "multiline comment" {
  let s =
    #|
    #|# Start of env file
    #|# Comment line with single ' quote
    #|# Comment line with double " quote
    #| # Comment line with double " quote and starts with a space
    #|TESTKEY1=test_val # 1 '" comment
    #|TESTKEY2=test_val_with_#_hash # 2 '" comment
    #|TESTKEY3="test_val quoted with # hash" # 3 '" comment
    #|TESTKEY4="Line 1
    #|# Line 2
    #|Line 3" # 4 Multiline "' comment
    #|TESTKEY5="Line 4
    #|# Line 5
    #|Line 6
    #|" # 5 Multiline "' comment
    #|# End of env file
    #|
  let env_map = EnvLoader::from_string(s)
    .set_sequence(EnvSequence::InputOnly)
    .load()
  assert_eq(env_map.get("TESTKEY1").unwrap(), "test_val")
  assert_eq(env_map.get("TESTKEY2").unwrap(), "test_val_with_#_hash")
  assert_eq(env_map.get("TESTKEY3").unwrap(), "test_val quoted with # hash")
  assert_eq(env_map.get("TESTKEY4").unwrap(), "Line 1\n# Line 2\nLine 3")
  assert_eq(env_map.get("TESTKEY5").unwrap(), "Line 4\n# Line 5\nLine 6\n")
}

///|
test "non modify" {
  temp_env({ "SRC": "env" }, fn() -> Unit raise Error {
    let s = "SRC=envfile\nFOO=bar"
    let env_map = EnvLoader::from_string(s)
      .set_sequence(EnvSequence::EnvThenInput)
      .load()
    assert_eq(env_map.get("SRC").unwrap(), "envfile")
    assert_eq(env_map.get("FOO").unwrap(), "bar")
    let env_map = EnvLoader::from_string(s)
      .set_sequence(EnvSequence::InputThenEnv)
      .load()
    assert_eq(env_map.get("SRC").unwrap(), "env")
  })
}

///|
test "modify" {
  let s = "SRC=envfile\nFOO=bar"
  temp_env({ "SRC": "env" }, fn() -> Unit raise Error {
    let loader = EnvLoader::from_string(s).set_sequence(
      EnvSequence::InputThenEnv,
    )
    ignore(loader.load_and_modify())
    assert_eq(@sys.get_env_vars().get("SRC").unwrap(), "env")
    assert_eq(@sys.get_env_vars().get("FOO").unwrap(), "bar")
  })
  // override
  temp_env({ "SRC": "env" }, fn() -> Unit raise Error {
    let loader = EnvLoader::from_string(s).set_sequence(
      EnvSequence::EnvThenInput,
    )
    ignore(loader.load_and_modify())
    assert_eq(@sys.get_env_vars().get("SRC").unwrap(), "envfile")
    assert_eq(@sys.get_env_vars().get("FOO").unwrap(), "bar")
  })
}
