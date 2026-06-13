///|
test "fuzz: GeneratedContent from empty JSON" {
  let content = @generable.GeneratedContent::from_json_string("{}")
  defer content.release()
  assert_false!(content.has_property("anything"))
  assert_eq!(content.property_names().length(), 0)
  assert_eq!(content.value_as_float64("x"), None)
  assert_eq!(content.value_as_int64("x"), None)
  assert_eq!(content.value_as_bool("x"), None)
}

///|
test "fuzz: GeneratedContent from deeply nested JSON" {
  let json = "{\"a\":{\"b\":{\"c\":{\"d\":1}}}}"
  let content = @generable.GeneratedContent::from_json_string(json)
  defer content.release()
  assert_true!(content.has_property("a"))
  assert_eq!(content.property_names().length(), 1)
}

///|
test "fuzz: GeneratedContent from JSON with special characters" {
  let cases = [
    "{\"unicode\":\"日本語テスト\"}",
    "{\"empty\":\"\"}",
    "{\"space\":\"hello world\"}",
    "{\"num\":9223372036854775807}",
    "{\"neg\":-42}",
    "{\"float\":3.14}",
    "{\"bool_true\":true}",
    "{\"bool_false\":false}",
    "{\"null_val\":null}",
  ]
  for json in cases {
    let content = @generable.GeneratedContent::from_json_string(json)
    defer content.release()
    let _ = content.property_names()
    let _ = content.has_property("x")
    let _ = content.value_as_float64("x")
    let _ = content.value_as_int64("x")
    let _ = content.value_as_bool("x")
  }
}

///|
test "fuzz: GeneratedContent from JSON arrays and primitives" {
  let invalid_cases = [
    "[1,2,3]",
    "null",
    "42",
    "\"hello\"",
    "true",
  ]
  for json in invalid_cases {
    try {
      let content = @generable.GeneratedContent::from_json_string(json)
      defer content.release()
      let _ = content.property_names()
    } catch {
      _ => ()
    }
  }
}

///|
test "fuzz: GeneratedContent from random string seeds" {
  let seeds = [0, 1, 42, 100, 999, 12345, 65536]
  for seed in seeds {
    let rand_str = generate_random_string(seed, 20)
    let json = "{\"key\":\"" + rand_str + "\"}"
    try {
      let content = @generable.GeneratedContent::from_json_string(json)
      defer content.release()
      let _ = content.property_names()
      let _ = content.has_property("key")
      let _ = content.value_as_float64("key")
      let _ = content.value_as_int64("key")
      let _ = content.value_as_bool("key")
    } catch {
      _ => ()
    }
  }
}

///|
test "fuzz: GeneratedContent property access after release is safe" {
  let content = @generable.GeneratedContent::from_json_string("{\"score\":99}")
  content.release()
  // After release, operations should not crash.
  // MoonBit FFI may return safe defaults (None/false).
  assert_eq!(content.value_as_float64("score"), None)
  assert_eq!(content.value_as_int64("score"), None)
  assert_eq!(content.value_as_bool("score"), None)
  assert_false!(content.has_property("score"))
}