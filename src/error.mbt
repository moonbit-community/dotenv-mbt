///|
pub type! DotenvError {
  LineParseError(String, UInt)
  /// An IO error may be encountered when reading from a file.
  Io(Error, String)
  /// The variable was not found in the environment. The `String` is the name of the variable.
  NotPresent(String)
  /// When `load_and_modify` is called with `EnvSequence::EnvOnly`
  ///
  /// There is nothing to modify, so we consider this an invalid operation because of the unnecessary unsafe call.
  InvalidOp
}
