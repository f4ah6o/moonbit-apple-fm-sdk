///|
pub suberror FoundationModelsError {
  FoundationModelsError(String)
} derive(@debug.Debug)

///|
pub suberror GenerationError {
  ExceededContextWindowSize(String)
  AssetsUnavailable(String)
  GuardrailViolation(String)
  UnsupportedGuide(String)
  UnsupportedLanguageOrLocale(String)
  DecodingFailure(String)
  RateLimited(String)
  ConcurrentRequests(String)
  Refusal(String)
  InvalidSchema(String)
  UnknownGenerationError(String)
} derive(@debug.Debug)

///|
pub suberror ToolCallError {
  ToolCallError(String)
} derive(@debug.Debug)

///|
pub suberror PromptError {
  PromptError(String)
  ImagePromptError(String)
} derive(@debug.Debug)

///|
pub enum GenerationErrorCode {
  Success
  ExceededContextWindowSize
  AssetsUnavailable
  GuardrailViolation
  UnsupportedGuide
  UnsupportedLanguageOrLocale
  DecodingFailure
  RateLimited
  ConcurrentRequests
  Refusal
  InvalidSchema
  UnknownError
} derive(Eq, @debug.Debug)

///|
pub fn GenerationErrorCode::from_int(code : Int) -> GenerationErrorCode {
  match code {
    0 => Success
    1 => ExceededContextWindowSize
    2 => AssetsUnavailable
    3 => GuardrailViolation
    4 => UnsupportedGuide
    5 => UnsupportedLanguageOrLocale
    6 => DecodingFailure
    7 => RateLimited
    8 => ConcurrentRequests
    9 => Refusal
    10 => InvalidSchema
    _ => UnknownError
  }
}

///|
pub fn GenerationErrorCode::to_int(self : GenerationErrorCode) -> Int {
  match self {
    Success => 0
    ExceededContextWindowSize => 1
    AssetsUnavailable => 2
    GuardrailViolation => 3
    UnsupportedGuide => 4
    UnsupportedLanguageOrLocale => 5
    DecodingFailure => 6
    RateLimited => 7
    ConcurrentRequests => 8
    Refusal => 9
    InvalidSchema => 10
    UnknownError => 255
  }
}

///|
pub fn raise_prompt_error(description : String) -> Unit raise {
  raise PromptError::PromptError(description)
}

///|
pub fn raise_image_prompt_error(description : String) -> Unit raise {
  raise PromptError::ImagePromptError(description)
}

///|
pub fn raise_generation_error(
  code : Int,
  description : String
) -> Unit raise {
  let desc = if description.is_empty() {
    "Unknown error"
  } else {
    description
  }
  match code {
    1 => raise GenerationError::ExceededContextWindowSize(desc)
    2 => raise GenerationError::AssetsUnavailable(desc)
    3 => raise GenerationError::GuardrailViolation(desc)
    4 => raise GenerationError::UnsupportedGuide(desc)
    5 => raise GenerationError::UnsupportedLanguageOrLocale(desc)
    6 => raise GenerationError::DecodingFailure(desc)
    7 => raise GenerationError::RateLimited(desc)
    8 => raise GenerationError::ConcurrentRequests(desc)
    9 => raise GenerationError::Refusal(desc)
    10 => raise GenerationError::InvalidSchema(desc)
    _ => raise GenerationError::UnknownGenerationError(desc)
  }
}
