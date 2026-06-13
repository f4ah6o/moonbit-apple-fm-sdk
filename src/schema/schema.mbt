///|
pub struct GenerationSchema {
  ptr : @ffi.FMGenerationSchemaRef
  mut released : Bool
}

///|
pub fn GenerationSchema::new(
  name : String,
  description~ : String? = None,
  properties~ : Array[@property.Property] = [],
  reference_schemas~ : Array[GenerationSchema] = []
) -> GenerationSchema {
  let name_bytes = @ffi.string_to_utf8_bytes(name)
  let desc_bytes = match description {
    Some(d) => @ffi.string_to_utf8_bytes(d)
    None => Bytes::new(0)
  }
  let ptr = @ffi.generation_schema_create(name_bytes, desc_bytes)
  for ref_schema in reference_schemas {
    @ffi.generation_schema_add_reference_schema(ptr, ref_schema.ptr)
  }
  for prop in properties {
    prop.convert_to_c(ptr)
  }
  { ptr, released: false }
}

///|
pub fn GenerationSchema::release(self : GenerationSchema) -> Unit {
  if self.released {
    return
  }
  @ffi.release_schema(self.ptr)
  self.released = true
}
