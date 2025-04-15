///|
struct EnvMap {
  /// The map of environment variables.
  map : @hashmap.T[String, String]
}

///|
fn EnvMap::new() -> EnvMap {
  { map: @hashmap.new() }
}

///|
pub fn EnvMap::var(self : EnvMap, name : String) -> String? {
  self.map.get(name)
}

///|
pub(all) enum EnvSequence {
  /// Inherit the existing environment without loading from input.
  EnvOnly
  /// Inherit the existing environment, and then load from input, overriding existing values.
  EnvThenInput
  /// Load from input only.
  InputOnly
  /// Load from input and then inherit the existing environment. Values in the existing environment are not overwritten.
  InputThenEnv
}

///|
pub impl Default for EnvSequence with default() {
  EnvSequence::InputThenEnv
}

///|
pub struct EnvLoader {
  mut path : String?
  priv str : String
  priv mut sequence : EnvSequence
}

///|
pub fn EnvLoader::new() -> EnvLoader!DotenvError {
  /// Creates a new `EnvLoader` with the path set to `./.env` in the current directory.
  EnvLoader::from_path!("./.env")
}

///|
pub fn EnvLoader::from_path(path : String) -> EnvLoader!DotenvError {
  let str = @fs.read_file_to_string?(path)
    .map_err(fn(e) { DotenvError::Io(e, path) })
    .unwrap_or_error!()
  { path: Some(path), str, sequence: EnvSequence::default() }
}

///|
pub fn EnvLoader::from_string(str : String) -> EnvLoader {
  { path: None, str, sequence: EnvSequence::default() }
}

///| Sets the path to the specified path.
///
/// This is useful when constructing with a reader, but still desiring a path to be used in the error message context.
///
/// If a reader exists and a path is specified, loading will be done using the reader.
pub fn EnvLoader::set_path(self : EnvLoader, path : String?) -> EnvLoader {
  self.path = path
  self
}

///| Sets the sequence in which to load environment variables.
pub fn EnvLoader::set_sequence(
  self : EnvLoader,
  sequence : EnvSequence
) -> EnvLoader {
  self.sequence = sequence
  self
}

///|
fn EnvLoader::load_input(self : EnvLoader) -> EnvMap!DotenvError {
  let iter = DotenvIter::new(self.str)
  iter
  .load?()
  .map_err(fn(e) {
    match e {
      ParseBufError::LineParse(line, pos) =>
        DotenvError::LineParseError(line, pos)
    }
  })
  .unwrap_or_error!()
}

///|
fn EnvLoader::load_input_and_modify(self : EnvLoader) -> EnvMap!DotenvError {
  let iter = DotenvIter::new(self.str)
  iter
  .load_and_modify?()
  .map_err(fn(e) {
    match e {
      ParseBufError::LineParse(line, pos) =>
        DotenvError::LineParseError(line, pos)
    }
  })
  .unwrap_or_error!()
}

///|
fn EnvLoader::load_input_and_modify_override(
  self : EnvLoader
) -> EnvMap!DotenvError {
  let iter = DotenvIter::new(self.str)
  iter
  .load_and_modify_override?()
  .map_err(fn(e) {
    match e {
      ParseBufError::LineParse(line, pos) =>
        DotenvError::LineParseError(line, pos)
    }
  })
  .unwrap_or_error!()
}

///|
fn env_vars() -> @hashmap.T[String, String] {
  let vars = @sys.get_env_vars()
  @hashmap.from_iter(vars.iter())
}

///| Loads environment variables into a hash map.
///
/// This is the primary method for loading environment variables.
pub fn EnvLoader::load(self : EnvLoader) -> EnvMap!DotenvError {
  match self.sequence {
    EnvOnly => { map: env_vars() }
    EnvThenInput => {
      let existing = env_vars()
      let input = self.load_input!()
      input.map.each(fn(k, v) { existing.set(k, v) })
      { map: existing }
    }
    InputOnly => self.load_input!()
    InputThenEnv => {
      let input = self.load_input!()
      let existing = env_vars()
      existing.each(fn(k, v) { input.map.set(k, v) })
      input
    }
  }
}

///| Loads environment variables into a hash map, modifying the existing environment.
///
/// This calls `@sys.set_env_var` internally.
pub fn EnvLoader::load_and_modify(self : EnvLoader) -> EnvMap!DotenvError {
  match self.sequence {
    InputOnly => raise DotenvError::InvalidOp
    EnvThenInput => {
      let existing = env_vars()
      let input = self.load_input_and_modify_override!()
      input.map.each(fn(k, v) { existing.set(k, v) })
      { map: existing }
    }
    EnvOnly => self.load_input_and_modify_override!()
    InputThenEnv => {
      let existing = env_vars()
      let input = self.load_input_and_modify!()
      input.map.each(fn(k, v) {
        if not(existing.contains(k)) {
          @sys.set_env_var(k, v)
        }
      })
      existing.each(fn(k, v) { input.map.set(k, v) })
      input
    }
  }
}
