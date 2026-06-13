///|
test "fuzz: Resource lifecycle — double release GeneratedContent" {
  let content = @generable.GeneratedContent::from_json_string("{\"x\":1}")
  content.release()
  content.release()
}

///|
test "fuzz: Transcript from valid JSON round-trip" {
  let session = @session.LanguageModelSession::new()
  let json = session.transcript.to_json_string()
  assert_false!(json.is_empty())
  try {
    let restored = @session.LanguageModelSession::from_transcript(json)
    assert_false!(restored.is_responding())
  } catch {
    _ => ()
  }
}

///|
test "fuzz: Transcript from invalid JSON returns error or is safe" {
  let invalid_cases = ["", "not json", "null", "[]", "42", "{}"]
  for json in invalid_cases {
    try {
      let _ = @session.LanguageModelSession::from_transcript(json)
    } catch {
      _ => ()
    }
  }
}

///|
test "fuzz: Schema release is idempotent" {
  let schema = @schema.GenerationSchema::new(
    "TestSchema",
    properties=[
      @property.Property::new("field", "String"),
    ],
  )
  schema.release()
  schema.release()
}
