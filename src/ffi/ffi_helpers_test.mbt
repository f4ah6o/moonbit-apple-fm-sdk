test "string_to_utf8_bytes ASCII string" {
  let bytes = string_to_utf8_bytes("hello")
  assert_eq!(bytes.length(), 6)
  assert_eq!(bytes[0], b'h')
  assert_eq!(bytes[1], b'e')
  assert_eq!(bytes[2], b'l')
  assert_eq!(bytes[3], b'l')
  assert_eq!(bytes[4], b'o')
  assert_eq!(bytes[5], b'\x00')
}

test "string_to_utf8_bytes empty string" {
  let bytes = string_to_utf8_bytes("")
  assert_eq!(bytes.length(), 1)
  assert_eq!(bytes[0], b'\x00')
}

test "string_to_utf8_bytes multibyte UTF-8" {
  let bytes = string_to_utf8_bytes("日本")
  assert_eq!(bytes[bytes.length() - 1], b'\x00')
  assert_true!(bytes.length() > 3)
}

test "string_to_utf8_bytes null terminated" {
  let strings = ["a", "test", "hello world", ""]
  for s in strings {
    let bytes = string_to_utf8_bytes(s)
    assert_eq!(bytes[bytes.length() - 1], b'\x00')
  }
}
