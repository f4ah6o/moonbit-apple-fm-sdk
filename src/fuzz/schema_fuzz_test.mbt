///|
test "fuzz: Schema creation with various type names" {
  let type_names = [
    "String", "Int", "Double", "Bool",
    generate_random_string(7, 10),
  ]
  for type_name in type_names {
    let schema = @schema.GenerationSchema::new(
      "FuzzSchema",
      description=Some("fuzz test"),
      properties=[
        @property.Property::new("field1", type_name, is_optional=true),
      ],
    )
    schema.release()
  }
}

///|
test "fuzz: Schema with regex guide patterns" {
  let patterns = ["[a-z]+", "\\d+", "[A-Za-z0-9]+", "^$", ""]
  for pattern in patterns {
    let schema = @schema.GenerationSchema::new(
      "RegexSchema",
      properties=[
        @property.Property::new("field1", "String", guides=[@guide.GenerationGuide::regex(pattern)]),
      ],
    )
    schema.release()
  }
}

///|
test "fuzz: Schema with all guide types" {
  let schema = @schema.GenerationSchema::new(
    "FullGuideSchema",
    description=Some("all guide types"),
    properties=[
      @property.Property::new(
        "name",
        "String",
        guides=[@guide.GenerationGuide::any_of(["red", "green", "blue"])],
      ),
      @property.Property::new(
        "count",
        "Int",
        is_optional=true,
        guides=[@guide.GenerationGuide::count(5)],
      ),
      @property.Property::new(
        "score",
        "Double",
        guides=[@guide.GenerationGuide::minimum(0.0), @guide.GenerationGuide::maximum(100.0)],
      ),
      @property.Property::new(
        "range_field",
        "Double",
        guides=[@guide.GenerationGuide::range(0.0, 1.0)],
      ),
    ],
  )
  schema.release()
}

///|
test "fuzz: Schema with empty name" {
  let schema = @schema.GenerationSchema::new(
    "",
    properties=[],
  )
  schema.release()
}

///|
test "fuzz: Schema with random name" {
  let seeds = [0, 1, 42, 100, 999]
  for seed in seeds {
    let name = generate_random_string(seed, 15)
    let schema = @schema.GenerationSchema::new(name, properties=[])
    schema.release()
  }
}