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

test "new session transcript entry count is zero" {
  let session = @session.LanguageModelSession::new()
  assert_eq!(session.transcript.entry_count(), 0)
}

test "from_transcript round trip" {
  let orig = @session.LanguageModelSession::new()
  let json = orig.transcript.to_json_string()
  assert_false!(json.is_empty())
  let restored = @session.LanguageModelSession::from_transcript(json)
  assert_false!(restored.is_responding())
}
