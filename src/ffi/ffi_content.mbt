///|
#borrow(json_string, out_error_code, out_error_description)
extern "c" fn fm_generated_content_create_from_json(
  json_string : Bytes,
  out_error_code : Bytes,
  out_error_description : Bytes
) -> FMGeneratedContentRef = "FMGeneratedContentCreateFromJSON"

///|
#borrow(content)
extern "c" fn fm_generated_content_get_json_string(
  content : FMGeneratedContentRef
) -> CString = "FMGeneratedContentGetJSONString"

///|
#borrow(content)
extern "c" fn fm_generated_content_is_complete(
  content : FMGeneratedContentRef
) -> Bool = "FMGeneratedContentIsComplete"

///|
pub fn generated_content_create_from_json(
  json_string : Bytes
) -> (FMGeneratedContentRef, Int) {
  let error_code = Bytes::new(4)
  let error_desc = Bytes::new(8)
  let ptr = fm_generated_content_create_from_json(
    json_string, error_code, error_desc,
  )
  let code = error_code[0].to_int()
  (ptr, code)
}

///|
pub fn generated_content_get_json_string(
  content : FMGeneratedContentRef
) -> CString {
  fm_generated_content_get_json_string(content)
}

///|
pub fn generated_content_is_complete(
  content : FMGeneratedContentRef
) -> Bool {
  fm_generated_content_is_complete(content)
}
