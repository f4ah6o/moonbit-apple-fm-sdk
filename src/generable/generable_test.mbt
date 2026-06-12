///|
struct Point {
  x : Int
  y : Double
} derive(FromJson)

///|
struct Contact {
  name : String
  email : String?
  tags : Array[String]
} derive(FromJson)

///|
test "decode generated content to struct" {
  let content = @generable.GeneratedContent::from_json_string(
    "{\"x\": 1, \"y\": 2.5}",
  )
  defer content.release()
  let p : Point = content.decode()
  assert_eq(p.x, 1)
  assert_eq(p.y, 2.5)
}

///|
test "decode struct with optional and array fields" {
  let content = @generable.GeneratedContent::from_json_string(
    "{\"name\": \"Alice\", \"tags\": [\"work\", \"vip\"]}",
  )
  defer content.release()
  let c : Contact = content.decode()
  assert_eq(c.name, "Alice")
  assert_eq(c.email, None)
  assert_eq(c.tags, ["work", "vip"])
}

///|
test "value_as_float64" {
  let content = @generable.GeneratedContent::from_json_string(
    "{\"price\": 3.14, \"count\": 7, \"label\": \"hi\"}",
  )
  defer content.release()
  assert_eq(content.value_as_float64("price"), Some(3.14))
  assert_eq(content.value_as_float64("missing"), None)
  assert_eq(content.value_as_float64("label"), None)
}

///|
test "value_as_int64" {
  let content = @generable.GeneratedContent::from_json_string(
    "{\"count\": 7, \"price\": 3.14, \"label\": \"hi\"}",
  )
  defer content.release()
  assert_eq(content.value_as_int64("count"), Some(7L))
  assert_eq(content.value_as_int64("missing"), None)
  assert_eq(content.value_as_int64("label"), None)
}

///|
test "value_as_bool" {
  let content = @generable.GeneratedContent::from_json_string(
    "{\"active\": true, \"disabled\": false, \"label\": \"hi\"}",
  )
  defer content.release()
  assert_eq(content.value_as_bool("active"), Some(true))
  assert_eq(content.value_as_bool("disabled"), Some(false))
  assert_eq(content.value_as_bool("label"), None)
  assert_eq(content.value_as_bool("missing"), None)
}

///|
test "has_property" {
  let content = @generable.GeneratedContent::from_json_string(
    "{\"x\": 1, \"y\": 2.5}",
  )
  defer content.release()
  assert_true(content.has_property("x"))
  assert_true(content.has_property("y"))
  assert_false(content.has_property("z"))
}

///|
test "property_names" {
  let content = @generable.GeneratedContent::from_json_string(
    "{\"a\": 1, \"b\": 2, \"c\": 3}",
  )
  defer content.release()
  let names = content.property_names()
  assert_eq(names.length(), 3)
  assert_true(names.contains("a"))
  assert_true(names.contains("b"))
  assert_true(names.contains("c"))
}

///|
test "decode error on wrong shape" {
  let content = @generable.GeneratedContent::from_json_string(
    "{\"x\": \"oops\", \"y\": 2.5}",
  )
  defer content.release()
  try (content.decode() : Point) |> ignore catch {
    @json.JsonDecodeError(_) => ()
  } noraise {
    _ => fail("expected JsonDecodeError")
  }
}
