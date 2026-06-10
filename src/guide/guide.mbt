///|
pub enum GuideType {
  AnyOf
  Constant
  Count
  Element
  MaxItems
  Maximum
  MinItems
  Minimum
  Range
  Regex
} derive(Eq, @debug.Debug)

///|
pub struct GenerationGuide {
  guide_type : GuideType
  string_values : Array[String]
  int_value : Int
  double_value : Double
  double_value2 : Double
  inner_guide : GenerationGuide?
} derive(@debug.Debug)

///|
fn default_guide(guide_type : GuideType) -> GenerationGuide {
  {
    guide_type,
    string_values: [],
    int_value: 0,
    double_value: 0.0,
    double_value2: 0.0,
    inner_guide: None,
  }
}

///|
pub fn GenerationGuide::any_of(values : Array[String]) -> GenerationGuide {
  { ..default_guide(AnyOf), string_values: values }
}

///|
pub fn GenerationGuide::constant(value : String) -> GenerationGuide {
  { ..default_guide(Constant), string_values: [value] }
}

///|
pub fn GenerationGuide::count(count : Int) -> GenerationGuide {
  { ..default_guide(Count), int_value: count }
}

///|
pub fn GenerationGuide::element(
  inner : GenerationGuide
) -> GenerationGuide {
  { ..default_guide(Element), inner_guide: Some(inner) }
}

///|
pub fn GenerationGuide::max_items(value : Int) -> GenerationGuide {
  { ..default_guide(MaxItems), int_value: value }
}

///|
pub fn GenerationGuide::maximum(value : Double) -> GenerationGuide {
  { ..default_guide(Maximum), double_value: value }
}

///|
pub fn GenerationGuide::min_items(value : Int) -> GenerationGuide {
  { ..default_guide(MinItems), int_value: value }
}

///|
pub fn GenerationGuide::minimum(value : Double) -> GenerationGuide {
  { ..default_guide(Minimum), double_value: value }
}

///|
pub fn GenerationGuide::range(
  min_val : Double,
  max_val : Double
) -> GenerationGuide {
  { ..default_guide(Range), double_value: min_val, double_value2: max_val }
}

///|
pub fn GenerationGuide::regex(pattern : String) -> GenerationGuide {
  { ..default_guide(Regex), string_values: [pattern] }
}

///|
pub fn GenerationGuide::convert_to_c(
  self : GenerationGuide,
  prop_ptr : @ffi.FMGenerationSchemaPropertyRef
) -> Unit {
  let mut guide_type = self.guide_type
  let mut string_values = self.string_values
  let mut int_value = self.int_value
  let mut double_value = self.double_value
  let mut double_value2 = self.double_value2
  let mut wrapped = false
  if guide_type == Element {
    match self.inner_guide {
      Some(inner) => {
        guide_type = inner.guide_type
        string_values = inner.string_values
        int_value = inner.int_value
        double_value = inner.double_value
        double_value2 = inner.double_value2
        wrapped = true
      }
      None => ()
    }
  }
  match guide_type {
    AnyOf => convert_any_of_to_c(string_values, prop_ptr, wrapped)
    Constant => convert_any_of_to_c(string_values, prop_ptr, wrapped)
    Count =>
      @ffi.schema_property_add_count_guide(prop_ptr, int_value, wrapped)
    MaxItems => @ffi.schema_property_add_max_items_guide(prop_ptr, int_value)
    Maximum =>
      @ffi.schema_property_add_maximum_guide(prop_ptr, double_value, wrapped)
    MinItems => @ffi.schema_property_add_min_items_guide(prop_ptr, int_value)
    Minimum =>
      @ffi.schema_property_add_minimum_guide(prop_ptr, double_value, wrapped)
    Range =>
      @ffi.schema_property_add_range_guide(
        prop_ptr, double_value, double_value2, wrapped,
      )
    Regex => {
      let pattern_bytes = @ffi.string_to_utf8_bytes(string_values[0])
      @ffi.schema_property_add_regex(prop_ptr, pattern_bytes, wrapped)
    }
    Element => ()
  }
}

///|
fn convert_any_of_to_c(
  values : Array[String],
  prop_ptr : @ffi.FMGenerationSchemaPropertyRef,
  wrapped : Bool
) -> Unit {
  let count = values.length()
  let buf : Array[Byte] = []
  for v in values {
    let vb = @ffi.string_to_utf8_bytes(v)
    for i in 0..<vb.length() {
      buf.push(vb[i])
    }
  }
  let packed = Bytes::from_array(buf[:])
  @ffi.schema_property_add_any_of_guide(prop_ptr, packed, count, wrapped)
}
