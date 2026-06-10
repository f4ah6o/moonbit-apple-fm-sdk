///|
pub struct LanguageModelSession {
  ptr : @ffi.FMLanguageModelSessionRef
  transcript : @transcript.Transcript
}

///|
pub fn LanguageModelSession::new(
  instructions~ : String? = None,
  model~ : @core.SystemLanguageModel? = None
) -> LanguageModelSession {
  let ptr = match (model, instructions) {
    (Some(m), Some(instr)) => {
      let instr_bytes = @ffi.string_to_utf8_bytes(instr)
      @ffi.session_create(m.ptr, instr_bytes)
    }
    (Some(m), None) =>
      @ffi.session_create(m.ptr, Bytes::new(0))
    (None, Some(instr)) => {
      let default_model = @core.SystemLanguageModel::get_default()
      let instr_bytes = @ffi.string_to_utf8_bytes(instr)
      let p = @ffi.session_create(default_model.ptr, instr_bytes)
      default_model.release()
      p
    }
    (None, None) => @ffi.session_create_default()
  }
  let transcript = @transcript.Transcript::new(ptr)
  { ptr, transcript }
}

///|
pub fn LanguageModelSession::is_responding(
  self : LanguageModelSession
) -> Bool {
  @ffi.session_is_responding(self.ptr)
}

///|
pub fn LanguageModelSession::reset(self : LanguageModelSession) -> Unit {
  @ffi.session_reset(self.ptr)
}

///|
pub fn LanguageModelSession::respond(
  self : LanguageModelSession,
  prompt : String,
  options~ : @options.GenerationOptions? = None
) -> String raise {
  let composed = @ffi.composed_prompt_initialize()
  let text_bytes = @ffi.string_to_utf8_bytes(prompt)
  @ffi.composed_prompt_add_text(composed, text_bytes)
  let options_bytes = match options {
    Some(opts) => @ffi.string_to_utf8_bytes(opts.to_json().stringify())
    None => Bytes::new(0)
  }
  let task = @ffi.session_respond(self.ptr, composed, options_bytes)
  let (status, content) = @ffi.read_response(65536)
  @ffi.release_task(task)
  if status != 0 {
    @errors.raise_generation_error(status, content)
  }
  content
}

///|
pub fn LanguageModelSession::respond_with_schema(
  self : LanguageModelSession,
  prompt : String,
  schema : @schema.GenerationSchema,
  options~ : @options.GenerationOptions? = None
) -> @generable.GeneratedContent raise {
  let composed = @ffi.composed_prompt_initialize()
  let text_bytes = @ffi.string_to_utf8_bytes(prompt)
  @ffi.composed_prompt_add_text(composed, text_bytes)
  let options_bytes = match options {
    Some(opts) => @ffi.string_to_utf8_bytes(opts.to_json().stringify())
    None => Bytes::new(0)
  }
  let task = @ffi.session_respond_with_schema(
    self.ptr, composed, schema.ptr, options_bytes,
  )
  let (status, content) = @ffi.read_response(65536)
  @ffi.release_task(task)
  if status != 0 {
    @errors.raise_generation_error(status, content)
  }
  @generable.GeneratedContent::from_json_string(content)
}

///|
pub fn LanguageModelSession::respond_with_json_schema(
  self : LanguageModelSession,
  prompt : String,
  json_schema : String,
  options~ : @options.GenerationOptions? = None
) -> @generable.GeneratedContent raise {
  let composed = @ffi.composed_prompt_initialize()
  let text_bytes = @ffi.string_to_utf8_bytes(prompt)
  @ffi.composed_prompt_add_text(composed, text_bytes)
  let schema_bytes = @ffi.string_to_utf8_bytes(json_schema)
  let options_bytes = match options {
    Some(opts) => @ffi.string_to_utf8_bytes(opts.to_json().stringify())
    None => Bytes::new(0)
  }
  let task = @ffi.session_respond_with_json_schema(
    self.ptr, composed, schema_bytes, options_bytes,
  )
  let (status, content) = @ffi.read_response(65536)
  @ffi.release_task(task)
  if status != 0 {
    @errors.raise_generation_error(status, content)
  }
  @generable.GeneratedContent::from_json_string(content)
}

///|
/// Structured output: generate a value of type T directly from the model.
/// T provides its schema via Generable::generation_schema() and is decoded
/// via Generable::from_generated_content().
pub fn[T : @generable.Generable] LanguageModelSession::extract(
  self : LanguageModelSession,
  prompt : String,
  options~ : @options.GenerationOptions? = None
) -> T raise {
  let schema = T::generation_schema()
  defer schema.release()
  let content = self.respond_with_schema(prompt, schema, options~)
  defer content.release()
  T::from_generated_content(content)
}

///|
/// Structured output from a raw JSON schema string; T only needs
/// derive(FromJson), no Generable impl required.
pub fn[T : @json.FromJson] LanguageModelSession::extract_with_json_schema(
  self : LanguageModelSession,
  prompt : String,
  json_schema : String,
  options~ : @options.GenerationOptions? = None
) -> T raise {
  let content = self.respond_with_json_schema(prompt, json_schema, options~)
  defer content.release()
  content.decode()
}

///|
pub fn LanguageModelSession::stream_response(
  self : LanguageModelSession,
  prompt : String,
  options~ : @options.GenerationOptions? = None,
  on_chunk~ : (String) -> Unit = fn(_s) {  }
) -> String raise {
  let composed = @ffi.composed_prompt_initialize()
  let text_bytes = @ffi.string_to_utf8_bytes(prompt)
  @ffi.composed_prompt_add_text(composed, text_bytes)
  let options_bytes = match options {
    Some(opts) => @ffi.string_to_utf8_bytes(opts.to_json().stringify())
    None => Bytes::new(0)
  }
  let stream = @ffi.session_stream_response(self.ptr, composed, options_bytes)
  @ffi.stream_start_iterate(stream)
  let mut last_content = ""
  while true {
    let (status, content) = @ffi.read_response(65536)
    if status != 0 {
      @ffi.release_stream(stream)
      @errors.raise_generation_error(status, content)
    }
    if content.is_empty() {
      break
    }
    last_content = content
    on_chunk(content)
  }
  @ffi.release_stream(stream)
  last_content
}

///|
pub fn LanguageModelSession::release(self : LanguageModelSession) -> Unit {
  @ffi.release_session(self.ptr)
  @ffi.cleanup_pipe()
}
