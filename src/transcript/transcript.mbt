///|
pub struct Transcript {
  session_ptr : @ffi.FMLanguageModelSessionRef
}

///|
pub fn Transcript::new(
  session_ptr : @ffi.FMLanguageModelSessionRef
) -> Transcript {
  { session_ptr, }
}

///|
pub fn Transcript::to_json_string(
  self : Transcript
) -> String raise {
  let (json_cstr, error_code) = @ffi.session_get_transcript_json_string(
    self.session_ptr,
  )
  if error_code != 0 {
    @ffi.free_string(json_cstr)
    @errors.raise_generation_error(
      error_code, "Failed to fetch session transcript",
    )
  }
  @ffi.cstring_to_string(json_cstr)
}

///|
pub fn Transcript::from_json_string(
  json_str : String
) -> Transcript raise {
  let json_bytes = @ffi.string_to_utf8_bytes(json_str)
  let (session_ptr, error_code) = @ffi.transcript_create_from_json(json_bytes)
  if error_code != 0 {
    @errors.raise_generation_error(
      error_code, "Failed to create transcript from JSON",
    )
  }
  { session_ptr, }
}
