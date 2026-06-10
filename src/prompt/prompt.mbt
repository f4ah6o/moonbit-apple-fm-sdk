///|
pub(open) trait Attachment {
  add_to_composed_prompt(Self, @ffi.FMComposedPromptRef) -> Unit raise
}

///|
pub struct ImageAttachment {
  path : String
  label : String?
}

///|
pub fn ImageAttachment::new(
  path : String,
  label~ : String? = None
) -> ImageAttachment {
  { path, label }
}

///|
pub impl Attachment for ImageAttachment with add_to_composed_prompt(
  self,
  prompt
) -> Unit {
  let path_bytes = @ffi.string_to_utf8_bytes(self.path)
  let label_bytes = match self.label {
    Some(l) => @ffi.string_to_utf8_bytes(l)
    None => Bytes::new(0)
  }
  let (ok, _error_code) = @ffi.composed_prompt_add_attachment(
    prompt, path_bytes, label_bytes,
  )
  if !ok {
    @errors.raise_image_prompt_error("Failed to add attachment to prompt")
  }
}

///|
pub enum PromptComponent {
  Text(String)
  Image(ImageAttachment)
}

///|
pub fn compose_prompt(
  components : Array[PromptComponent]
) -> @ffi.FMComposedPromptRef raise {
  let prompt = @ffi.composed_prompt_initialize()
  for component in components {
    match component {
      Text(text) => {
        let text_bytes = @ffi.string_to_utf8_bytes(text)
        @ffi.composed_prompt_add_text(prompt, text_bytes)
      }
      Image(attachment) => attachment.add_to_composed_prompt(prompt)
    }
  }
  prompt
}
