///|
test "remove bom" {
  // BOM present
  let b = "\xEF\xBB\xBFkey=value\n"
  let iter = DotenvIter::new(b)
  iter.remove_bom()
  assert_eq!(iter.cursor.read_line(), "key=value\n")
}

///|
test "remove bom no bom" {
  // no BOM
  let b = "key=value\n"
  let iter = DotenvIter::new(b)
  iter.remove_bom()
  assert_eq!(iter.cursor.read_line(), "key=value\n")
}
