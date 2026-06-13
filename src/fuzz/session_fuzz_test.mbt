///|
test "fuzz: Session prewarm with various prefixes" {
  let session = @session.LanguageModelSession::new()
  session.prewarm()
  session.prewarm(prompt_prefix="")
  session.prewarm(prompt_prefix="short")
  session.prewarm(prompt_prefix="multi\nline\ntext")
  session.prewarm(prompt_prefix=generate_random_string(42, 100))
  assert_false!(session.is_responding())
}

///|
test "fuzz: Session reset is idempotent" {
  let session = @session.LanguageModelSession::new()
  session.reset()
  session.reset()
  session.reset()
  assert_false!(session.is_responding())
}

///|
test "fuzz: Session transcript round-trip with malformed JSON" {
  let malformed_cases = [
    "",
    "not json",
    "null",
    "[]",
    "42",
    "{\"version\":1}",
    "{\"transcript\":null}",
  ]
  for json in malformed_cases {
    try {
      let session = @session.LanguageModelSession::from_transcript(json)
      assert_false!(session.is_responding())
    } catch {
      _ => ()
    }
  }
}

///|
test "fuzz: New session with random instructions" {
  let seeds = [0, 1, 42, 100, 999]
  for seed in seeds {
    let instr = generate_random_string(seed, 20)
    let session = @session.LanguageModelSession::new(
      instructions=Some(instr),
    )
    assert_false!(session.is_responding())
    assert_eq!(session.transcript.entry_count(), 0)
  }
}