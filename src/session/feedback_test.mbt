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
