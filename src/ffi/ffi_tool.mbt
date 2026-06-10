///|
#borrow(tool, output)
extern "c" fn fm_bridged_tool_finish_call(
  tool : FMBridgedToolRef,
  call_id : UInt,
  output : Bytes
) = "FMBridgedToolFinishCall"

///|
#borrow(name, description, parameters, out_error_code, out_error_description)
extern "c" fn moonbit_fm_tool_create_fn(
  name : Bytes,
  description : Bytes,
  parameters : FMGenerationSchemaRef,
  out_error_code : Bytes,
  out_error_description : Bytes
) -> FMBridgedToolRef = "moonbit_fm_tool_create"

///|
#borrow(out_call_id, out_json, out_actual_len)
extern "c" fn moonbit_fm_tool_read_call_fn(
  out_call_id : Bytes,
  out_json : Bytes,
  max_len : Int,
  out_actual_len : Bytes
) -> Int = "moonbit_fm_tool_read_call"

///|
extern "c" fn moonbit_fm_tool_cleanup_fn() = "moonbit_fm_tool_cleanup"

///|
pub fn bridged_tool_finish_call(
  tool : FMBridgedToolRef,
  call_id : UInt,
  output : Bytes
) -> Unit {
  fm_bridged_tool_finish_call(tool, call_id, output)
}

///|
pub fn tool_create(
  name : Bytes,
  description : Bytes,
  parameters : FMGenerationSchemaRef
) -> (FMBridgedToolRef, Int) {
  let error_code = Bytes::new(4)
  let error_desc = Bytes::new(8)
  let ptr = moonbit_fm_tool_create_fn(
    name, description, parameters, error_code, error_desc,
  )
  let code = error_code[0].to_int()
  (ptr, code)
}

///|
pub fn tool_read_call(max_len : Int) -> (Int, UInt, String) {
  let call_id_buf = Bytes::new(4)
  let json_buf = Bytes::new(max_len)
  let len_buf = Bytes::new(8)
  let status = moonbit_fm_tool_read_call_fn(
    call_id_buf, json_buf, max_len, len_buf,
  )
  let call_id = call_id_buf[0].to_int().reinterpret_as_uint() |
    (call_id_buf[1].to_int().reinterpret_as_uint() << 4) |
    (call_id_buf[2].to_int().reinterpret_as_uint() << 8) |
    (call_id_buf[3].to_int().reinterpret_as_uint() << 12)
  let actual_len = len_buf[0].to_int() |
    (len_buf[1].to_int() << 8) |
    (len_buf[2].to_int() << 16) |
    (len_buf[3].to_int() << 24)
  let json = if actual_len > 0 {
    json_buf.to_unchecked_string(offset=0, length=actual_len)
  } else {
    ""
  }
  (status, call_id, json)
}

///|
pub fn tool_cleanup() -> Unit {
  moonbit_fm_tool_cleanup_fn()
}
