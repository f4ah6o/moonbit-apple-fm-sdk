///|
fn generate_random_string(seed : Int, length : Int) -> String {
  let mut buf = ""
  let mut s = seed
  for i = 0; i < length; i = i + 1 {
    s = (s * 1103515245 + 12345).land(0x7FFFFFFF)
    let code = s % 95 + 32
    buf = buf + Int::unsafe_to_char(code).to_string()
  }
  buf
}

///|
test "generators produce deterministic output" {
  let s1 = generate_random_string(42, 5)
  let s2 = generate_random_string(42, 5)
  assert_eq!(s1, s2)
  assert_eq!(s1.length(), 5)
}
