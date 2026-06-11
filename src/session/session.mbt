///|
pub struct LanguageModelSession {
  ptr : @ffi.FMLanguageModelSessionRef
  transcript : @transcript.Transcript
}

///|
pub fn LanguageModelSession::new(
  instructions~ : String? = None,
  model~ : @core.SystemLanguageModel? = None,
  tools~ : Array[@tool.BridgedTool] = []
) -> LanguageModelSession {
  let tool_refs = tools.map(fn(t) { t.ptr })
  let ptr = if tools.length() > 0 {
    let model_owned = match model {
      Some(_) => false
      None => true
    }
    let m = match model {
      Some(m) => m
      None => @core.SystemLanguageModel::get_default()
    }
    let instr_bytes = match instructions {
      Some(s) => @ffi.string_to_utf8_bytes(s)
      None => Bytes::new(0)
    }
    let p = @ffi.session_create_with_tools(m.ptr, instr_bytes, tool_refs)
    if model_owned {
      m.release()
    }
    p
  } else {
    match (model, instructions) {
      (Some(m), Some(instr)) => {
        let instr_bytes = @ffi.string_to_utf8_bytes(instr)
        @ffi.session_create(m.ptr, instr_bytes)
      }
      (Some(m), None) => @ffi.session_create(m.ptr, Bytes::new(0))
      (None, Some(instr)) => {
        let default_model = @core.SystemLanguageModel::get_default()
        let instr_bytes = @ffi.string_to_utf8_bytes(instr)
        let p = @ffi.session_create(default_model.ptr, instr_bytes)
        default_model.release()
        p
      }
      (None, None) => @ffi.session_create_default()
    }
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
/// Ask the system to pre-load resources for this session so the first request
/// has lower latency. `prompt_prefix`, when non-empty, is the prefix the next
/// prompt is expected to start with. Prewarm is a fire-and-forget hint and is
/// safe to call regardless of model availability.
pub fn LanguageModelSession::prewarm(
  self : LanguageModelSession,
  prompt_prefix~ : String = ""
) -> Unit {
  @ffi.session_prewarm(self.ptr, @ffi.string_to_utf8_bytes(prompt_prefix))
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
/// Low-level entry for schema-constrained snapshot streaming: composes the
/// prompt and starts the stream + iteration. The caller drives the read loop
/// via @ffi.read_response (each frame is a full cumulative partial JSON;
/// an empty frame signals completion) and must @ffi.release_stream the
/// returned ref when done. Useful when snapshots must be consumed from an
/// async context where a sync callback won't do.
pub fn LanguageModelSession::start_structured_stream(
  self : LanguageModelSession,
  prompt : String,
  schema : @schema.GenerationSchema,
  options~ : @options.GenerationOptions? = None
) -> @ffi.FMLanguageModelSessionResponseStreamRef {
  let composed = @ffi.composed_prompt_initialize()
  let text_bytes = @ffi.string_to_utf8_bytes(prompt)
  @ffi.composed_prompt_add_text(composed, text_bytes)
  let options_bytes = match options {
    Some(opts) => @ffi.string_to_utf8_bytes(opts.to_json().stringify())
    None => Bytes::new(0)
  }
  let stream = @ffi.session_stream_response_with_schema(
    self.ptr, composed, schema.ptr, options_bytes,
  )
  @ffi.structured_stream_start_iterate(stream)
  stream
}

///|
/// Schema-constrained snapshot streaming (guided generation).
/// Each on_snapshot call receives the FULL cumulative partial JSON of the
/// generated value so far — a structurally valid prefix of the schema, not a
/// delta. Returns the final complete JSON string.
pub fn LanguageModelSession::stream_response_with_schema(
  self : LanguageModelSession,
  prompt : String,
  schema : @schema.GenerationSchema,
  options~ : @options.GenerationOptions? = None,
  on_snapshot~ : (String) -> Unit = fn(_s) {  }
) -> String raise {
  let stream = self.start_structured_stream(prompt, schema, options~)
  let mut last_content = ""
  while true {
    let (status, content) = @ffi.read_response(262144)
    if status != 0 {
      @ffi.release_stream(stream)
      @errors.raise_generation_error(status, content)
    }
    if content.is_empty() {
      break
    }
    last_content = content
    on_snapshot(content)
  }
  @ffi.release_stream(stream)
  last_content
}

///|
pub fn LanguageModelSession::release(self : LanguageModelSession) -> Unit {
  @ffi.release_session(self.ptr)
  @ffi.cleanup_pipe()
}
