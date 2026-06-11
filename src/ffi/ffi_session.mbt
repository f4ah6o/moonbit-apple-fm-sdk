///|
extern "c" fn fm_language_model_session_create_default() -> FMLanguageModelSessionRef = "FMLanguageModelSessionCreateDefault"

///|
#borrow(model, instructions)
extern "c" fn moonbit_fm_session_create_fn(
  model : FMSystemLanguageModelRef,
  instructions : Bytes,
  tool_count : Int
) -> FMLanguageModelSessionRef = "moonbit_fm_session_create"

///|
#borrow(session)
extern "c" fn fm_language_model_session_is_responding(
  session : FMLanguageModelSessionRef
) -> Bool = "FMLanguageModelSessionIsResponding"

///|
#borrow(session)
extern "c" fn fm_language_model_session_reset(
  session : FMLanguageModelSessionRef
) = "FMLanguageModelSessionReset"

///|
#borrow(session, prompt_prefix)
extern "c" fn moonbit_fm_session_prewarm_fn(
  session : FMLanguageModelSessionRef,
  prompt_prefix : Bytes
) = "moonbit_fm_session_prewarm"

///|
#borrow(json_string, out_error_code, out_error_description)
extern "c" fn fm_transcript_create_from_json_string(
  json_string : Bytes,
  out_error_code : Bytes,
  out_error_description : Bytes
) -> FMLanguageModelSessionRef = "FMTranscriptCreateFromJSONString"

///|
#borrow(session, out_error_code, out_error_description)
extern "c" fn fm_language_model_session_get_transcript_json_string(
  session : FMLanguageModelSessionRef,
  out_error_code : Bytes,
  out_error_description : Bytes
) -> CString = "FMLanguageModelSessionGetTranscriptJSONString"

///|
#borrow(session, prompt, options_json)
extern "c" fn moonbit_fm_session_respond_fn(
  session : FMLanguageModelSessionRef,
  prompt : FMComposedPromptRef,
  options_json : Bytes
) -> FMTaskRef = "moonbit_fm_session_respond"

///|
#borrow(session, prompt, schema, options_json)
extern "c" fn moonbit_fm_session_respond_with_schema_fn(
  session : FMLanguageModelSessionRef,
  prompt : FMComposedPromptRef,
  schema : FMGenerationSchemaRef,
  options_json : Bytes
) -> FMTaskRef = "moonbit_fm_session_respond_with_schema"

///|
#borrow(session, prompt, schema_json, options_json)
extern "c" fn moonbit_fm_session_respond_with_json_schema_fn(
  session : FMLanguageModelSessionRef,
  prompt : FMComposedPromptRef,
  schema_json : Bytes,
  options_json : Bytes
) -> FMTaskRef = "moonbit_fm_session_respond_with_json_schema"

///|
#borrow(out_content, out_actual_len)
extern "c" fn moonbit_fm_read_response_fn(
  out_content : Bytes,
  max_len : Int,
  out_actual_len : Bytes
) -> Int = "moonbit_fm_read_response"

///|
extern "c" fn moonbit_fm_cleanup_pipe_fn() = "moonbit_fm_cleanup_pipe"

///|
#borrow(session, prompt, options_json)
extern "c" fn moonbit_fm_session_stream_response_fn(
  session : FMLanguageModelSessionRef,
  prompt : FMComposedPromptRef,
  options_json : Bytes
) -> FMLanguageModelSessionResponseStreamRef = "moonbit_fm_session_stream_response"

///|
#borrow(stream)
extern "c" fn moonbit_fm_stream_start_iterate_fn(
  stream : FMLanguageModelSessionResponseStreamRef
) = "moonbit_fm_stream_start_iterate"

///|
#borrow(session, prompt, schema, options_json)
extern "c" fn moonbit_fm_session_stream_response_with_schema_fn(
  session : FMLanguageModelSessionRef,
  prompt : FMComposedPromptRef,
  schema : FMGenerationSchemaRef,
  options_json : Bytes
) -> FMLanguageModelSessionResponseStreamRef = "moonbit_fm_session_stream_response_with_schema"

///|
#borrow(stream)
extern "c" fn moonbit_fm_structured_stream_start_iterate_fn(
  stream : FMLanguageModelSessionResponseStreamRef
) = "moonbit_fm_structured_stream_start_iterate"

///|
pub fn session_create_default() -> FMLanguageModelSessionRef {
  fm_language_model_session_create_default()
}

///|
pub fn session_create(
  model : FMSystemLanguageModelRef,
  instructions : Bytes
) -> FMLanguageModelSessionRef {
  moonbit_fm_session_create_fn(model, instructions, 0)
}

///|
pub fn session_is_responding(
  session : FMLanguageModelSessionRef
) -> Bool {
  fm_language_model_session_is_responding(session)
}

///|
pub fn session_reset(session : FMLanguageModelSessionRef) -> Unit {
  fm_language_model_session_reset(session)
}

///|
/// Prewarm the session. An empty `prompt_prefix` means "no prefix".
pub fn session_prewarm(
  session : FMLanguageModelSessionRef,
  prompt_prefix : Bytes
) -> Unit {
  moonbit_fm_session_prewarm_fn(session, prompt_prefix)
}

///|
pub fn session_respond(
  session : FMLanguageModelSessionRef,
  prompt : FMComposedPromptRef,
  options_json : Bytes
) -> FMTaskRef {
  moonbit_fm_session_respond_fn(session, prompt, options_json)
}

///|
pub fn session_respond_with_schema(
  session : FMLanguageModelSessionRef,
  prompt : FMComposedPromptRef,
  schema : FMGenerationSchemaRef,
  options_json : Bytes
) -> FMTaskRef {
  moonbit_fm_session_respond_with_schema_fn(
    session, prompt, schema, options_json,
  )
}

///|
pub fn session_respond_with_json_schema(
  session : FMLanguageModelSessionRef,
  prompt : FMComposedPromptRef,
  schema_json : Bytes,
  options_json : Bytes
) -> FMTaskRef {
  moonbit_fm_session_respond_with_json_schema_fn(
    session, prompt, schema_json, options_json,
  )
}

///|
pub fn read_response(max_len : Int) -> (Int, String) {
  let buf = Bytes::new(max_len)
  let len_buf = Bytes::new(8)
  let status = moonbit_fm_read_response_fn(buf, max_len, len_buf)
  let actual_len = len_buf[0].to_int() |
    (len_buf[1].to_int() << 8) |
    (len_buf[2].to_int() << 16) |
    (len_buf[3].to_int() << 24)
  let content = if actual_len > 0 {
    @utf8.decode_lossy(buf[0:actual_len])
  } else {
    ""
  }
  (status, content)
}

///|
pub fn cleanup_pipe() -> Unit {
  moonbit_fm_cleanup_pipe_fn()
}

///|
pub fn session_stream_response(
  session : FMLanguageModelSessionRef,
  prompt : FMComposedPromptRef,
  options_json : Bytes
) -> FMLanguageModelSessionResponseStreamRef {
  moonbit_fm_session_stream_response_fn(session, prompt, options_json)
}

///|
pub fn stream_start_iterate(
  stream : FMLanguageModelSessionResponseStreamRef
) -> Unit {
  moonbit_fm_stream_start_iterate_fn(stream)
}

///|
pub fn session_stream_response_with_schema(
  session : FMLanguageModelSessionRef,
  prompt : FMComposedPromptRef,
  schema : FMGenerationSchemaRef,
  options_json : Bytes
) -> FMLanguageModelSessionResponseStreamRef {
  moonbit_fm_session_stream_response_with_schema_fn(
    session, prompt, schema, options_json,
  )
}

///|
pub fn structured_stream_start_iterate(
  stream : FMLanguageModelSessionResponseStreamRef
) -> Unit {
  moonbit_fm_structured_stream_start_iterate_fn(stream)
}

///|
pub fn transcript_create_from_json(
  json_string : Bytes
) -> (FMLanguageModelSessionRef, Int) {
  let error_code = Bytes::new(4)
  let error_desc = Bytes::new(8)
  let ptr = fm_transcript_create_from_json_string(
    json_string, error_code, error_desc,
  )
  let code = error_code[0].to_int()
  (ptr, code)
}

///|
pub fn session_get_transcript_json_string(
  session : FMLanguageModelSessionRef
) -> (CString, Int) {
  let error_code = Bytes::new(4)
  let error_desc = Bytes::new(8)
  let json = fm_language_model_session_get_transcript_json_string(
    session, error_code, error_desc,
  )
  let code = error_code[0].to_int()
  (json, code)
}
