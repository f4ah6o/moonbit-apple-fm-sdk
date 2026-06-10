///|
pub struct GeneratedContent {
  ptr : @ffi.FMGeneratedContentRef
  json_data : Json
}

///|
pub fn GeneratedContent::from_json_string(
  json_str : String
) -> GeneratedContent raise {
  let json_bytes = @ffi.string_to_utf8_bytes(json_str)
  let (ptr, error_code) = @ffi.generated_content_create_from_json(json_bytes)
  if error_code != 0 {
    @errors.raise_generation_error(error_code, "Failed to create GeneratedContent")
  }
  let data = @json.parse(json_str)
  { ptr, json_data: data }
}

///|
pub fn GeneratedContent::from_ptr(
  ptr : @ffi.FMGeneratedContentRef
) -> GeneratedContent {
  let json_cstr = @ffi.generated_content_get_json_string(ptr)
  ignore(json_cstr)
  { ptr, json_data: Json::null() }
}

///|
pub fn GeneratedContent::is_complete(self : GeneratedContent) -> Bool {
  @ffi.generated_content_is_complete(self.ptr)
}

///|
pub fn GeneratedContent::json(self : GeneratedContent) -> Json {
  self.json_data
}

///|
pub fn GeneratedContent::release(self : GeneratedContent) -> Unit {
  @ffi.release_content(self.ptr)
}

///|
pub(open) trait Generable {
  generation_schema() -> @schema.GenerationSchema
  from_generated_content(GeneratedContent) -> Self raise
  to_generated_content(Self) -> GeneratedContent raise
}
