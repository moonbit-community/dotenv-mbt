///|
/// This function is for testing only.
/// Do not use this in production code.
/// It is not thread-safe.
pub fn[R, E : Error] temp_env(
  temp_envs : Map[String, String],
  f : () -> R raise E,
) -> R raise E {
  let original_vars = @env.get_env_vars()
  for key, value in temp_envs {
    @env.set_env_var(key, value)
  }
  errdefer (for key, value in original_vars {
    @env.set_env_var(key, value)
  })
  let result = f()
  for key, value in original_vars {
    @env.set_env_var(key, value)
  }
  result
}
