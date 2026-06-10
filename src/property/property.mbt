///|
pub struct Property {
  name : String
  type_name : String
  description : String?
  is_optional : Bool
  guides : Array[@guide.GenerationGuide]
}

///|
pub fn Property::new(
  name : String,
  type_name : String,
  description~ : String? = None,
  is_optional~ : Bool = false,
  guides~ : Array[@guide.GenerationGuide] = []
) -> Property {
  { name, type_name, description, is_optional, guides }
}

///|
pub fn Property::convert_to_c(
  self : Property,
  schema_ptr : @ffi.FMGenerationSchemaRef
) -> Unit {
  let name_bytes = @ffi.string_to_utf8_bytes(self.name)
  let desc_bytes = match self.description {
    Some(d) => @ffi.string_to_utf8_bytes(d)
    None => Bytes::new(0)
  }
  let type_bytes = @ffi.string_to_utf8_bytes(
    @type_conversion.moonbit_type_to_swift_string(self.type_name),
  )
  let prop_ptr = @ffi.generation_schema_property_create(
    name_bytes, desc_bytes, type_bytes, self.is_optional,
  )
  for guide in self.guides {
    guide.convert_to_c(prop_ptr)
  }
  @ffi.generation_schema_add_property(schema_ptr, prop_ptr)
  @ffi.release_property(prop_ptr)
}
