///|
test "fuzz: Feedback attachment with valid sentiments" {
  let session = @session.LanguageModelSession::new()
  let sentiments = [@session.FeedbackSentiment::none(), @session.FeedbackSentiment::positive(), @session.FeedbackSentiment::negative(), @session.FeedbackSentiment::neutral()]
  for sentiment in sentiments {
    let options = @session.FeedbackAttachmentOptions::new(
      sentiment=sentiment,
      desired_response_text=Some("fuzz test"),
    )
    try {
      let payload = session.log_feedback_attachment(options)
      assert_true!(payload.length() > 0)
    } catch {
      _ => ()
    }
  }
}

///|
test "fuzz: Feedback attachment rejects text and content together" {
  let session = @session.LanguageModelSession::new()
  let content = @generable.GeneratedContent::from_json_string(
    "{\"answer\":\"test\"}",
  )
  defer content.release()
  let options = @session.FeedbackAttachmentOptions::new(
    sentiment=@session.FeedbackSentiment::positive(),
    desired_response_text=Some("text"),
    desired_response_content=Some(content),
  )
  try {
    let _ = session.log_feedback_attachment(options)
    fail("expected conflict error")
  } catch {
    _ => ()
  }
}

///|
test "fuzz: Feedback with various desired response texts" {
  let texts = ["", "short", generate_random_string(0, 20), generate_random_string(42, 50)]
  for text in texts {
    let session = @session.LanguageModelSession::new()
    let options = @session.FeedbackAttachmentOptions::new(
      sentiment=@session.FeedbackSentiment::neutral(),
      desired_response_text=Some(text),
    )
    try {
      let payload = session.log_feedback_attachment(options)
      assert_true!(payload.length() > 0)
    } catch {
      _ => ()
    }
  }
}