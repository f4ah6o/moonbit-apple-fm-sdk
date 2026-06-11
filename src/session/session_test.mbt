test "new session is not responding" {
  let session = @session.LanguageModelSession::new()
  assert_false!(session.is_responding())
}

test "session with instructions is not responding" {
  let session = @session.LanguageModelSession::new(
    instructions=Some("You are a helpful assistant."),
  )
  assert_false!(session.is_responding())
}

test "prewarm is safe with and without prefix" {
  let session = @session.LanguageModelSession::new()
  // Prewarm is a fire-and-forget hint; both forms must be safe and must not
  // flip the session into a responding state.
  session.prewarm()
  session.prewarm(prompt_prefix="Summarize the following text:")
  assert_false!(session.is_responding())
}

test "reset is safe" {
  let session = @session.LanguageModelSession::new()
  session.reset()
  assert_false!(session.is_responding())
}
