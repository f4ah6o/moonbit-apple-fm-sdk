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
  let json_str = @ffi.cstring_to_string(json_cstr)
  let json_data = if json_str.is_empty() {
    Json::null()
  } else {
    try {
      @json.parse(json_str)
    } catch {
      _ => Json::null()
    }
  }
  { ptr, json_data }
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
/// Decode the generated content's JSON into any type implementing
/// @json.FromJson (e.g. a struct with derive(FromJson)).
///
/// Note: Int64/UInt64 FromJson expect string-encoded JSON values, so prefer
/// Int/Double fields for model output. Optional fields should be `T?` and
/// marked `is_optional=true` in the schema; with derive(FromJson) a missing
/// key decodes to None, but an explicit JSON `null` value fails to decode.
pub fn[T : @json.FromJson] GeneratedContent::decode(
  self : GeneratedContent
) -> T raise @json.JsonDecodeError {
  @json.from_json(self.json_data)
}

///|
pub(open) trait Generable {
  generation_schema() -> @schema.GenerationSchema
  from_generated_content(GeneratedContent) -> Self raise
  to_generated_content(Self) -> GeneratedContent raise
}
