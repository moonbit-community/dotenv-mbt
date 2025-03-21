///| This function is for testing only.
/// Do not use this in production code.
/// It is not thread-safe.
pub fn temp_env[R, E : Error](
  temp_envs : Map[String, String],
  f : () -> R!E
) -> R!E {
  let original_vars = @sys.get_env_vars()
  for key, value in temp_envs {
    @sys.set_env_var(key, value)
  }
  let result = f?()
  for key, value in original_vars {
    @sys.set_env_var(key, value)
  }
  result.unwrap_or_error!()
}
