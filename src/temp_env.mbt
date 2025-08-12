///| This function is for testing only.
/// Do not use this in production code.
/// It is not thread-safe.
pub fn[R, E : Error] temp_env(
  temp_envs : Map[String, String],
  f : () -> R raise E,
) -> R raise E {
  let original_vars = @sys.get_env_vars()
  for key, value in temp_envs {
    @sys.set_env_var(key, value)
  }
  let result = f() catch {
    e => {
      // Restore environment before re-raising
      for key, value in original_vars {
        @sys.set_env_var(key, value)
      }
      raise e
    }
  }
  for key, value in original_vars {
    @sys.set_env_var(key, value)
  }
  result
}
