///|
test "log_feedback_attachment returns payload" {
  let session = @session.LanguageModelSession::new()
  let payload = session.log_feedback_attachment(
    @session.FeedbackAttachmentOptions::new(
      sentiment=@session.FeedbackSentiment::negative(),
      issues=[
        @session.FeedbackIssue::new(
          @session.FeedbackIssueCategory::incorrect(),
          explanation=Some("Expected a shorter response."),
        ),
      ],
      desired_response_text=Some("A shorter desired response."),
    ),
  )
  inspect(payload.length() > 0, content="true")
  session.release()
}

///|
test "log_feedback_attachment with desired response content returns payload" {
  let session = @session.LanguageModelSession::new()
  let content = @generable.GeneratedContent::from_json_string(
    "{\"answer\":\"A concise desired response.\"}",
  )
  let payload = session.log_feedback_attachment(
    @session.FeedbackAttachmentOptions::new(
      sentiment=@session.FeedbackSentiment::positive(),
      desired_response_content=Some(content),
    ),
  )
  inspect(payload.length() > 0, content="true")
  content.release()
  session.release()
}

///|
test "log_feedback_attachment rejects text and content" {
  let session = @session.LanguageModelSession::new()
  let content = @generable.GeneratedContent::from_json_string(
    "{\"answer\":\"A concise desired response.\"}",
  )
  let mut caught = false
  try {
    session.log_feedback_attachment(
      @session.FeedbackAttachmentOptions::new(
        sentiment=@session.FeedbackSentiment::positive(),
        desired_response_text=Some("A text response."),
        desired_response_content=Some(content),
      ),
    ) |> ignore
  } catch {
    _ => caught = true
  }
  inspect(caught, content="true")
  content.release()
  session.release()
}
