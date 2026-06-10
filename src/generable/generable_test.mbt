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
