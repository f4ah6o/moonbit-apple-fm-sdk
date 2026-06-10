test "moonbit_type_to_swift_string basic types" {
  assert_eq!(moonbit_type_to_swift_string("String"), "string")
  assert_eq!(moonbit_type_to_swift_string("Int"), "integer")
  assert_eq!(moonbit_type_to_swift_string("Double"), "number")
  assert_eq!(moonbit_type_to_swift_string("Float"), "number")
  assert_eq!(moonbit_type_to_swift_string("Bool"), "boolean")
}

test "moonbit_type_to_swift_string array types" {
  assert_eq!(moonbit_type_to_swift_string("Array[String]"), "array<string>")
  assert_eq!(moonbit_type_to_swift_string("Array[Int]"), "array<integer>")
  assert_eq!(moonbit_type_to_swift_string("Array[Double]"), "array<number>")
  assert_eq!(moonbit_type_to_swift_string("Array[Bool]"), "array<boolean>")
}

test "moonbit_type_to_swift_string nested array types" {
  assert_eq!(
    moonbit_type_to_swift_string("Array[Array[String]]"),
    "array<array<string>>",
  )
}

test "moonbit_type_to_swift_string unknown types pass through" {
  assert_eq!(moonbit_type_to_swift_string("MyCustomType"), "MyCustomType")
  assert_eq!(moonbit_type_to_swift_string("Product"), "Product")
}
