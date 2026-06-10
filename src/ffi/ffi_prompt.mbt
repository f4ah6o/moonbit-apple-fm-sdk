///|
extern "c" fn fm_composed_prompt_initialize() -> FMComposedPromptRef = "FMComposedPromptInitialize"

///|
#borrow(composed_prompt, text)
extern "c" fn fm_composed_prompt_add_text(
  composed_prompt : FMComposedPromptRef,
  text : Bytes
) = "FMComposedPromptAddText"

///|
#borrow(composed_prompt, image_path, label, error)
extern "c" fn fm_composed_prompt_add_attachment(
  composed_prompt : FMComposedPromptRef,
  image_path : Bytes,
  label : Bytes,
  error : Bytes
) -> Bool = "FMComposedPromptAddAttachment"

///|
pub fn composed_prompt_initialize() -> FMComposedPromptRef {
  fm_composed_prompt_initialize()
}

///|
pub fn composed_prompt_add_text(
  prompt : FMComposedPromptRef,
  text : Bytes
) -> Unit {
  fm_composed_prompt_add_text(prompt, text)
}

///|
pub fn composed_prompt_add_attachment(
  prompt : FMComposedPromptRef,
  image_path : Bytes,
  label : Bytes
) -> (Bool, Int) {
  let error_buf = Bytes::new(4)
  let ok = fm_composed_prompt_add_attachment(prompt, image_path, label, error_buf)
  let error_code = error_buf[0].to_int()
  (ok, error_code)
}
