test "GenerationErrorCode from_int roundtrip for all codes" {
  let codes = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  for code in codes {
    let error_code = GenerationErrorCode::from_int(code)
    assert_true!(error_code.to_int() == code)
  }
}

test "GenerationErrorCode unknown codes map to 255" {
  assert_true!(GenerationErrorCode::from_int(11).to_int() == 255)
  assert_true!(GenerationErrorCode::from_int(255).to_int() == 255)
  assert_true!(GenerationErrorCode::from_int(-1).to_int() == 255)
  assert_true!(GenerationErrorCode::from_int(999).to_int() == 255)
}

test "GenerationErrorCode from_int produces distinct values" {
  let c0 = GenerationErrorCode::from_int(0)
  let c1 = GenerationErrorCode::from_int(1)
  let c3 = GenerationErrorCode::from_int(3)
  assert_true!(c0 != c1)
  assert_true!(c1 != c3)
  assert_true!(c0 == GenerationErrorCode::from_int(0))
}

test "raise_generation_error raises ExceededContextWindowSize for code 1" {
  let mut caught = false
  try {
    raise_generation_error(1, "test")
  } catch {
    GenerationError::ExceededContextWindowSize(msg) => {
      assert_true!(msg == "test")
      caught = true
    }
    _ => ()
  }
  assert_true!(caught)
}

test "raise_generation_error raises AssetsUnavailable for code 2" {
  let mut caught = false
  try {
    raise_generation_error(2, "assets down")
  } catch {
    GenerationError::AssetsUnavailable(msg) => {
      assert_true!(msg == "assets down")
      caught = true
    }
    _ => ()
  }
  assert_true!(caught)
}

test "raise_generation_error raises GuardrailViolation for code 3" {
  let mut caught = false
  try {
    raise_generation_error(3, "safety violation")
  } catch {
    GenerationError::GuardrailViolation(msg) => {
      assert_true!(msg == "safety violation")
      caught = true
    }
    _ => ()
  }
  assert_true!(caught)
}

test "raise_generation_error raises UnsupportedGuide for code 4" {
  let mut caught = false
  try {
    raise_generation_error(4, "bad guide")
  } catch {
    GenerationError::UnsupportedGuide(msg) => {
      assert_true!(msg == "bad guide")
      caught = true
    }
    _ => ()
  }
  assert_true!(caught)
}

test "raise_generation_error raises UnsupportedLanguageOrLocale for code 5" {
  let mut caught = false
  try {
    raise_generation_error(5, "bad locale")
  } catch {
    GenerationError::UnsupportedLanguageOrLocale(msg) => {
      assert_true!(msg == "bad locale")
      caught = true
    }
    _ => ()
  }
  assert_true!(caught)
}

test "raise_generation_error raises DecodingFailure for code 6" {
  let mut caught = false
  try {
    raise_generation_error(6, "decode fail")
  } catch {
    GenerationError::DecodingFailure(msg) => {
      assert_true!(msg == "decode fail")
      caught = true
    }
    _ => ()
  }
  assert_true!(caught)
}

test "raise_generation_error raises RateLimited for code 7" {
  let mut caught = false
  try {
    raise_generation_error(7, "too fast")
  } catch {
    GenerationError::RateLimited(msg) => {
      assert_true!(msg == "too fast")
      caught = true
    }
    _ => ()
  }
  assert_true!(caught)
}

test "raise_generation_error raises ConcurrentRequests for code 8" {
  let mut caught = false
  try {
    raise_generation_error(8, "concurrent")
  } catch {
    GenerationError::ConcurrentRequests(msg) => {
      assert_true!(msg == "concurrent")
      caught = true
    }
    _ => ()
  }
  assert_true!(caught)
}

test "raise_generation_error raises Refusal for code 9" {
  let mut caught = false
  try {
    raise_generation_error(9, "refused")
  } catch {
    GenerationError::Refusal(msg) => {
      assert_true!(msg == "refused")
      caught = true
    }
    _ => ()
  }
  assert_true!(caught)
}

test "raise_generation_error raises InvalidSchema for code 10" {
  let mut caught = false
  try {
    raise_generation_error(10, "bad schema")
  } catch {
    GenerationError::InvalidSchema(msg) => {
      assert_true!(msg == "bad schema")
      caught = true
    }
    _ => ()
  }
  assert_true!(caught)
}

test "raise_generation_error raises UnknownGenerationError for unknown code" {
  let mut caught = false
  try {
    raise_generation_error(999, "unexpected")
  } catch {
    GenerationError::UnknownGenerationError(msg) => {
      assert_true!(msg == "unexpected")
      caught = true
    }
    _ => ()
  }
  assert_true!(caught)
}

test "raise_generation_error uses default description for empty string" {
  let mut caught = false
  try {
    raise_generation_error(1, "")
  } catch {
    GenerationError::ExceededContextWindowSize(msg) => {
      assert_true!(msg == "Unknown error")
      caught = true
    }
    _ => ()
  }
  assert_true!(caught)
}

test "raise_prompt_error raises PromptError" {
  let mut caught = false
  try {
    raise_prompt_error("bad prompt")
  } catch {
    PromptError::PromptError(msg) => {
      assert_true!(msg == "bad prompt")
      caught = true
    }
    _ => ()
  }
  assert_true!(caught)
}

test "raise_image_prompt_error raises ImagePromptError" {
  let mut caught = false
  try {
    raise_image_prompt_error("bad image")
  } catch {
    PromptError::ImagePromptError(msg) => {
      assert_true!(msg == "bad image")
      caught = true
    }
    _ => ()
  }
  assert_true!(caught)
}
