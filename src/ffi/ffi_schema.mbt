///|
#borrow(name, description)
extern "c" fn fm_generation_schema_create(
  name : Bytes,
  description : Bytes
) -> FMGenerationSchemaRef = "FMGenerationSchemaCreate"

///|
#borrow(name, description, type_name)
extern "c" fn fm_generation_schema_property_create(
  name : Bytes,
  description : Bytes,
  type_name : Bytes,
  is_optional : Bool
) -> FMGenerationSchemaPropertyRef = "FMGenerationSchemaPropertyCreate"

///|
#borrow(schema, property)
extern "c" fn fm_generation_schema_add_property(
  schema : FMGenerationSchemaRef,
  property : FMGenerationSchemaPropertyRef
) = "FMGenerationSchemaAddProperty"

///|
#borrow(schema, reference_schema)
extern "c" fn fm_generation_schema_add_reference_schema(
  schema : FMGenerationSchemaRef,
  reference_schema : FMGenerationSchemaRef
) = "FMGenerationSchemaAddReferenceSchema"

///|
#borrow(property, packed_strings)
extern "c" fn moonbit_fm_property_add_any_of_guide(
  property : FMGenerationSchemaPropertyRef,
  packed_strings : Bytes,
  choice_count : Int,
  wrapped : Bool
) = "moonbit_fm_property_add_any_of_guide"

///|
#borrow(property)
extern "c" fn fm_generation_schema_property_add_count_guide(
  property : FMGenerationSchemaPropertyRef,
  count : Int,
  wrapped : Bool
) = "FMGenerationSchemaPropertyAddCountGuide"

///|
#borrow(property)
extern "c" fn fm_generation_schema_property_add_maximum_guide(
  property : FMGenerationSchemaPropertyRef,
  maximum : Double,
  wrapped : Bool
) = "FMGenerationSchemaPropertyAddMaximumGuide"

///|
#borrow(property)
extern "c" fn fm_generation_schema_property_add_minimum_guide(
  property : FMGenerationSchemaPropertyRef,
  minimum : Double,
  wrapped : Bool
) = "FMGenerationSchemaPropertyAddMinimumGuide"

///|
#borrow(property)
extern "c" fn fm_generation_schema_property_add_min_items_guide(
  property : FMGenerationSchemaPropertyRef,
  min_items : Int
) = "FMGenerationSchemaPropertyAddMinItemsGuide"

///|
#borrow(property)
extern "c" fn fm_generation_schema_property_add_max_items_guide(
  property : FMGenerationSchemaPropertyRef,
  max_items : Int
) = "FMGenerationSchemaPropertyAddMaxItemsGuide"

///|
#borrow(property)
extern "c" fn fm_generation_schema_property_add_range_guide(
  property : FMGenerationSchemaPropertyRef,
  min_value : Double,
  max_value : Double,
  wrapped : Bool
) = "FMGenerationSchemaPropertyAddRangeGuide"

///|
#borrow(property, pattern)
extern "c" fn fm_generation_schema_property_add_regex(
  property : FMGenerationSchemaPropertyRef,
  pattern : Bytes,
  wrapped : Bool
) = "FMGenerationSchemaPropertyAddRegex"

///|
pub fn generation_schema_create(
  name : Bytes,
  description : Bytes
) -> FMGenerationSchemaRef {
  fm_generation_schema_create(name, description)
}

///|
pub fn generation_schema_property_create(
  name : Bytes,
  description : Bytes,
  type_name : Bytes,
  is_optional : Bool
) -> FMGenerationSchemaPropertyRef {
  fm_generation_schema_property_create(name, description, type_name, is_optional)
}

///|
pub fn generation_schema_add_property(
  schema : FMGenerationSchemaRef,
  property : FMGenerationSchemaPropertyRef
) -> Unit {
  fm_generation_schema_add_property(schema, property)
}

///|
pub fn generation_schema_add_reference_schema(
  schema : FMGenerationSchemaRef,
  reference_schema : FMGenerationSchemaRef
) -> Unit {
  fm_generation_schema_add_reference_schema(schema, reference_schema)
}

///|
pub fn schema_property_add_any_of_guide(
  property : FMGenerationSchemaPropertyRef,
  packed_strings : Bytes,
  choice_count : Int,
  wrapped : Bool
) -> Unit {
  moonbit_fm_property_add_any_of_guide(
    property, packed_strings, choice_count, wrapped,
  )
}

///|
pub fn schema_property_add_count_guide(
  property : FMGenerationSchemaPropertyRef,
  count : Int,
  wrapped : Bool
) -> Unit {
  fm_generation_schema_property_add_count_guide(property, count, wrapped)
}

///|
pub fn schema_property_add_maximum_guide(
  property : FMGenerationSchemaPropertyRef,
  maximum : Double,
  wrapped : Bool
) -> Unit {
  fm_generation_schema_property_add_maximum_guide(property, maximum, wrapped)
}

///|
pub fn schema_property_add_minimum_guide(
  property : FMGenerationSchemaPropertyRef,
  minimum : Double,
  wrapped : Bool
) -> Unit {
  fm_generation_schema_property_add_minimum_guide(property, minimum, wrapped)
}

///|
pub fn schema_property_add_min_items_guide(
  property : FMGenerationSchemaPropertyRef,
  min_items : Int
) -> Unit {
  fm_generation_schema_property_add_min_items_guide(property, min_items)
}

///|
pub fn schema_property_add_max_items_guide(
  property : FMGenerationSchemaPropertyRef,
  max_items : Int
) -> Unit {
  fm_generation_schema_property_add_max_items_guide(property, max_items)
}

///|
pub fn schema_property_add_range_guide(
  property : FMGenerationSchemaPropertyRef,
  min_value : Double,
  max_value : Double,
  wrapped : Bool
) -> Unit {
  fm_generation_schema_property_add_range_guide(
    property, min_value, max_value, wrapped,
  )
}

///|
pub fn schema_property_add_regex(
  property : FMGenerationSchemaPropertyRef,
  pattern : Bytes,
  wrapped : Bool
) -> Unit {
  fm_generation_schema_property_add_regex(property, pattern, wrapped)
}
