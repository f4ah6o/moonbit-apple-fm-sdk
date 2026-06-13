///|
test "fuzz: type conversion with nested array-ish names" {
  let cases = [
    "String",
    "Int",
    "Double",
    "Float",
    "Bool",
    "Array[String]",
    "Array[Array[Int]]",
    "Array[Array[Array[Bool]]]",
    "Array[]",
    "Array[",
    generate_random_string(42, 12),
  ]
  for case in cases {
    let converted = @type_conversion.moonbit_type_to_swift_string(case)
    assert_true(converted.length() > 0)
  }
}

///|
test "fuzz: schema guide combinations stay releasable" {
  let seeds = [0, 1, 42, 100]
  for seed in seeds {
    let schema = @schema.GenerationSchema::new("GuideFuzz", properties=[
      @property.Property::new(
        generate_random_string(seed, 6),
        if seed % 2 == 0 {
          "Array[String]"
        } else {
          generate_random_string(seed + 1, 6)
        },
        guides=[
          @guide.GenerationGuide::any_of([
            "",
            "alpha",
            generate_random_string(seed + 2, 4),
          ]),
          @guide.GenerationGuide::constant(generate_random_string(seed + 3, 4)),
          @guide.GenerationGuide::count(seed - 1),
          @guide.GenerationGuide::min_items(seed - 2),
          @guide.GenerationGuide::max_items(seed + 2),
          @guide.GenerationGuide::minimum(-100.0),
          @guide.GenerationGuide::maximum(100.0),
          @guide.GenerationGuide::range(-1.0, 1.0),
          @guide.GenerationGuide::regex(generate_random_string(seed + 4, 3)),
          @guide.GenerationGuide::element(@guide.GenerationGuide::regex(".*")),
        ],
      ),
    ])
    schema.release()
  }
}
