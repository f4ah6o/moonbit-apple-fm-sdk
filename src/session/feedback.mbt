///|
pub enum FeedbackSentiment {
  NoSentiment
  Positive
  Negative
  Neutral
} derive(Eq)

///|
pub fn FeedbackSentiment::none() -> FeedbackSentiment {
  NoSentiment
}

///|
pub fn FeedbackSentiment::positive() -> FeedbackSentiment {
  Positive
}

///|
pub fn FeedbackSentiment::negative() -> FeedbackSentiment {
  Negative
}

///|
pub fn FeedbackSentiment::neutral() -> FeedbackSentiment {
  Neutral
}

///|
pub enum FeedbackIssueCategory {
  Unhelpful
  TooVerbose
  DidNotFollowInstructions
  Incorrect
  StereotypeOrBias
  SuggestiveOrSexual
  VulgarOrOffensive
  TriggeredGuardrailUnexpectedly
} derive(Eq)

///|
pub fn FeedbackIssueCategory::unhelpful() -> FeedbackIssueCategory {
  Unhelpful
}

///|
pub fn FeedbackIssueCategory::too_verbose() -> FeedbackIssueCategory {
  TooVerbose
}

///|
pub fn FeedbackIssueCategory::did_not_follow_instructions(
) -> FeedbackIssueCategory {
  DidNotFollowInstructions
}

///|
pub fn FeedbackIssueCategory::incorrect() -> FeedbackIssueCategory {
  Incorrect
}

///|
pub fn FeedbackIssueCategory::stereotype_or_bias() -> FeedbackIssueCategory {
  StereotypeOrBias
}

///|
pub fn FeedbackIssueCategory::suggestive_or_sexual() -> FeedbackIssueCategory {
  SuggestiveOrSexual
}

///|
pub fn FeedbackIssueCategory::vulgar_or_offensive() -> FeedbackIssueCategory {
  VulgarOrOffensive
}

///|
pub fn FeedbackIssueCategory::triggered_guardrail_unexpectedly(
) -> FeedbackIssueCategory {
  TriggeredGuardrailUnexpectedly
}

///|
pub struct FeedbackIssue {
  category : FeedbackIssueCategory
  explanation : String?
} derive(Eq)

///|
pub fn FeedbackIssue::new(
  category : FeedbackIssueCategory,
  explanation? : String? = None,
) -> FeedbackIssue {
  { category, explanation }
}

///|
pub struct FeedbackAttachmentOptions {
  sentiment : FeedbackSentiment
  issues : Array[FeedbackIssue]
  desired_response_text : String?
  desired_response_content : @generable.GeneratedContent?
}

///|
pub fn FeedbackAttachmentOptions::new(
  sentiment? : FeedbackSentiment = FeedbackSentiment::none(),
  issues? : Array[FeedbackIssue] = [],
  desired_response_text? : String? = None,
  desired_response_content? : @generable.GeneratedContent? = None,
) -> FeedbackAttachmentOptions {
  { sentiment, issues, desired_response_text, desired_response_content }
}

///|
pub fn LanguageModelSession::log_feedback_attachment(
  self : LanguageModelSession,
  options : FeedbackAttachmentOptions,
) -> Bytes raise {
  let has_desired_text = match options.desired_response_text {
    Some(_) => true
    None => false
  }
  let has_desired_content = match options.desired_response_content {
    Some(_) => true
    None => false
  }
  if has_desired_text && has_desired_content {
    @errors.raise_generation_error(
      255,
      "Feedback desired response text and content are mutually exclusive",
    )
  }
  let issues_json = issues_to_json(options.issues).stringify()
  let desired_text = match options.desired_response_text {
    Some(s) => s
    None => ""
  }
  let desired_content_json = match options.desired_response_content {
    Some(content) => content.json().stringify()
    None => ""
  }
  let max_len = 1048576
  let (status, buf, actual_len) = if has_desired_content {
    @ffi.session_log_feedback_attachment_with_desired_response_content(
      self.ptr,
      options.sentiment.to_ffi(),
      @ffi.string_to_utf8_bytes(issues_json),
      @ffi.string_to_utf8_bytes(desired_content_json),
      max_len,
    )
  } else {
    @ffi.session_log_feedback_attachment(
      self.ptr,
      options.sentiment.to_ffi(),
      @ffi.string_to_utf8_bytes(issues_json),
      @ffi.string_to_utf8_bytes(desired_text),
      max_len,
    )
  }
  if status != 0 {
    @errors.raise_generation_error(
      status, "Failed to create feedback attachment",
    )
  }
  if actual_len > max_len {
    @errors.raise_generation_error(
      255, "Feedback attachment exceeded buffer size",
    )
  }
  Bytes::makei(actual_len, fn(i) { buf[i] })
}

///|
fn FeedbackSentiment::to_ffi(self : FeedbackSentiment) -> Int {
  match self {
    NoSentiment => 0
    Positive => 1
    Negative => 2
    Neutral => 3
  }
}

///|
fn FeedbackIssueCategory::to_wire(self : FeedbackIssueCategory) -> String {
  match self {
    Unhelpful => "unhelpful"
    TooVerbose => "tooVerbose"
    DidNotFollowInstructions => "didNotFollowInstructions"
    Incorrect => "incorrect"
    StereotypeOrBias => "stereotypeOrBias"
    SuggestiveOrSexual => "suggestiveOrSexual"
    VulgarOrOffensive => "vulgarOrOffensive"
    TriggeredGuardrailUnexpectedly => "triggeredGuardrailUnexpectedly"
  }
}

///|
fn FeedbackIssue::to_json(self : FeedbackIssue) -> Json {
  let obj : Map[String, Json] = {}
  obj["category"] = Json::string(self.category.to_wire())
  match self.explanation {
    Some(s) => obj["explanation"] = Json::string(s)
    None => ()
  }
  Json::object(obj)
}

///|
fn issues_to_json(issues : Array[FeedbackIssue]) -> Json {
  Json::array(issues.map(FeedbackIssue::to_json))
}
