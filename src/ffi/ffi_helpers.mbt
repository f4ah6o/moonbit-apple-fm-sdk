///|
pub fn string_to_utf8_bytes(s : String) -> Bytes {
  let utf8 = @utf8.encode(s[:])
  let len = utf8.length()
  Bytes::makei(len + 1, fn(i) { if i < len { utf8[i] } else { b'\x00' } })
}
