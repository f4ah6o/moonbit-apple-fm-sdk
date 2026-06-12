///|
#borrow(session, issues_json, desired_response_text, out_content, out_actual_len)
extern "c" fn moonbit_fm_session_log_feedback_attachment_fn(
  session : FMLanguageModelSessionRef,
  sentiment : Int,
  issues_json : Bytes,
  desired_response_text : Bytes,
  out_content : Bytes,
  max_len : Int,
  out_actual_len : Bytes,
) -> Int = "moonbit_fm_session_log_feedback_attachment"

///|
pub fn session_log_feedback_attachment(
  session : FMLanguageModelSessionRef,
  sentiment : Int,
  issues_json : Bytes,
  desired_response_text : Bytes,
  max_len : Int,
) -> (Int, Bytes, Int) {
  let buf = Bytes::new(max_len)
  let len_buf = Bytes::new(8)
  let status = moonbit_fm_session_log_feedback_attachment_fn(
    session, sentiment, issues_json, desired_response_text, buf, max_len, len_buf,
  )
  let actual_len = len_buf[0].to_int() |
    (len_buf[1].to_int() << 8) |
    (len_buf[2].to_int() << 16) |
    (len_buf[3].to_int() << 24) |
    (len_buf[4].to_int() << 32) |
    (len_buf[5].to_int() << 40) |
    (len_buf[6].to_int() << 48) |
    (len_buf[7].to_int() << 56)
  (status, buf, actual_len)
}
