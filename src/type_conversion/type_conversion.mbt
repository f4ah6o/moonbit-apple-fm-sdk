///|
pub fn moonbit_type_to_swift_string(type_name : String) -> String {
  match type_name {
    "String" => "string"
    "Int" => "integer"
    "Double" | "Float" => "number"
    "Bool" => "boolean"
    _ =>
      if type_name.has_prefix("Array[") {
        let inner = type_name
          .view()[6 : type_name.length() - 1]
          .to_owned()
        let inner_swift = moonbit_type_to_swift_string(inner)
        "array<\{inner_swift}>"
      } else {
        type_name
      }
  }
}
