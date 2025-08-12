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
pub fn EnvMap::get(self : EnvMap, name : String) -> String? {
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
pub fn EnvLoader::from_path(path : String) -> EnvLoader raise DotenvError {
  let str = (try? @fs.read_file_to_string(path))
    .map_err(fn(e) { DotenvError::Io(e, path) })
    .unwrap_or_error()
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
  sequence : EnvSequence,
) -> EnvLoader {
  self.sequence = sequence
  self
}

///|
fn EnvLoader::load_input(self : EnvLoader) -> EnvMap raise DotenvError {
  let iter = DotenvIter::new(self.str)
  let result = try? iter.load()
  match result {
    Ok(env_map) => env_map
    Err(e) =>
      match e {
        ParseBufError::LineParse(line, pos) =>
          raise DotenvError::LineParseError(line, pos)
      }
  }
}

///|
fn EnvLoader::load_input_and_modify(
  self : EnvLoader,
) -> EnvMap raise DotenvError {
  let iter = DotenvIter::new(self.str)
  (try? iter.load_and_modify())
  .map_err(fn(e) {
    match e {
      ParseBufError::LineParse(line, pos) =>
        DotenvError::LineParseError(line, pos)
    }
  })
  .unwrap_or_error()
}

///|
fn EnvLoader::load_input_and_modify_override(
  self : EnvLoader,
) -> EnvMap raise DotenvError {
  let iter = DotenvIter::new(self.str)
  let result = try? iter.load_and_modify_override()
  result
  .map_err(fn(e) {
    match e {
      ParseBufError::LineParse(line, pos) =>
        DotenvError::LineParseError(line, pos)
    }
  })
  .unwrap_or_error()
}

///|
fn env_vars() -> @hashmap.T[String, String] {
  let vars = @sys.get_env_vars()
  @hashmap.from_iter(vars.iter())
}

///| Loads environment variables into a hash map.
///
/// This is the primary method for loading environment variables.
pub fn EnvLoader::load(self : EnvLoader) -> EnvMap raise DotenvError {
  match self.sequence {
    EnvOnly => { map: env_vars() }
    EnvThenInput => {
      let existing = env_vars()
      let input = self.load_input()
      input.map.each(fn(k, v) { existing.set(k, v) })
      { map: existing }
    }
    InputOnly => self.load_input()
    InputThenEnv => {
      let input = self.load_input()
      let existing = env_vars()
      existing.each(fn(k, v) { input.map.set(k, v) })
      input
    }
  }
}

///| Shortcut for loading environment variables from a file.
pub fn load(
  path~ : String = "./.env",
  ignore_file_not_found~ : Bool = true,
) -> EnvMap raise DotenvError {
  if @fs.path_exists(path) && (try? @fs.is_file(path)).or(false) {
    EnvLoader::from_path(path).load()
  } else if ignore_file_not_found {
    EnvLoader::from_string("").set_sequence(EnvSequence::EnvOnly).load()
  } else {
    raise DotenvError::FileNotFound(path)
  }
}

///| Loads environment variables into a hash map, modifying the existing environment.
///
/// This calls `@sys.set_env_var` internally.
pub fn EnvLoader::load_and_modify(self : EnvLoader) -> EnvMap raise DotenvError {
  match self.sequence {
    InputOnly => raise DotenvError::InvalidOp
    EnvThenInput => {
      let existing = env_vars()
      let input = self.load_input_and_modify_override()
      input.map.each(fn(k, v) { existing.set(k, v) })
      { map: existing }
    }
    EnvOnly => self.load_input_and_modify_override()
    InputThenEnv => {
      let existing = env_vars()
      let input = self.load_input_and_modify()
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

///| Shortcut for loading environment variables from a file and modifying the existing environment.
pub fn load_and_modify(
  path~ : String = "./.env",
  ignore_file_not_found~ : Bool = true,
) -> EnvMap raise DotenvError {
  if @fs.path_exists(path) && (try? @fs.is_file(path)).or(false) {
    EnvLoader::from_path(path).load_and_modify()
  } else if ignore_file_not_found {
    // If the file is not found, we do the same as in `load`.
    EnvLoader::from_string("").set_sequence(EnvSequence::EnvOnly).load()
  } else {
    raise DotenvError::FileNotFound(path)
  }
}
