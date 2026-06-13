///|
fn generate_random_string(seed : Int, length : Int) -> String {
  let mut buf = ""
  let mut s = seed
  for i = 0; i < length; i = i + 1 {
    s = (s * 1103515245 + 12345) % 2147483647
    let code = s % 95 + 32
    buf = buf + Int::unsafe_to_char(code).to_string()
  }
  buf
}