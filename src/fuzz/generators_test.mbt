///|
fn generate_random_string(seed : Int, length : Int) -> String {
  let chars = "abcdefghijklmnopqrstuvwxyz0123456789_ "
  let mut buf = ""
  let mut s = seed.abs()
  for i = 0; i < length; i = i + 1 {
    s = s * 1103515245 + 12345
    if s < 0 {
      s = -s
    }
    let idx = s % chars.length()
    buf = buf + chars[idx].to_string()
  }
  buf
}

///|
test "generators produce deterministic output" {
  let s1 = generate_random_string(42, 5)
  let s2 = generate_random_string(42, 5)
  assert_eq!(s1, s2)
  assert_true!(s1.length() == 5)
}