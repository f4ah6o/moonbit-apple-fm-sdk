///|
test "fuzz: ComposedPrompt with various text inputs" {
  let texts = [
    "",
    "hello",
    "日本語",
    generate_random_string(1, 10),
    generate_random_string(42, 200),
  ]
  for text in texts {
    let prompt = @ffi.composed_prompt_initialize()
    let text_bytes = @ffi.string_to_utf8_bytes(text)
    @ffi.composed_prompt_add_text(prompt, text_bytes)
    @ffi.release_prompt(prompt)
  }
}

///|
test "fuzz: ComposedPrompt with multiple text components" {
  let prompt = @ffi.composed_prompt_initialize()
  @ffi.composed_prompt_add_text(prompt, @ffi.string_to_utf8_bytes("First"))
  @ffi.composed_prompt_add_text(prompt, @ffi.string_to_utf8_bytes("Second"))
  @ffi.composed_prompt_add_text(prompt, @ffi.string_to_utf8_bytes("Third 日本語"))
  @ffi.release_prompt(prompt)
}

///|
test "fuzz: ComposedPrompt with empty text" {
  let prompt = @ffi.composed_prompt_initialize()
  @ffi.composed_prompt_add_text(prompt, @ffi.string_to_utf8_bytes(""))
  @ffi.release_prompt(prompt)
}