fn guide_is_minimum(g : @guide.GenerationGuide) -> Bool {
  match g.guide_type {
    Minimum => true
    _ => false
  }
}

fn guide_is_maximum(g : @guide.GenerationGuide) -> Bool {
  match g.guide_type {
    Maximum => true
    _ => false
  }
}

test "Property creation with defaults" {
  let prop = Property::new("name", "String")
  assert_eq!(prop.name, "name")
  assert_eq!(prop.type_name, "String")
  assert_true!(prop.description.is_empty())
  assert_true!(prop.is_optional == false)
  assert_true!(prop.guides.length() == 0)
}

test "Property creation with all fields" {
  let guides = [@guide.GenerationGuide::minimum(1.0)]
  let prop = Property::new(
    "price",
    "Double",
    description=Some("Product price"),
    is_optional=true,
    guides=guides,
  )
  assert_eq!(prop.name, "price")
  assert_eq!(prop.type_name, "Double")
  assert_eq!(prop.description, Some("Product price"))
  assert_true!(prop.is_optional == true)
  assert_true!(prop.guides.length() == 1)
}

test "Property with multiple guides" {
  let guides = [
    @guide.GenerationGuide::minimum(0.0),
    @guide.GenerationGuide::maximum(100.0),
  ]
  let prop = Property::new("score", "Double", guides=guides)
  assert_true!(prop.guides.length() == 2)
  assert_true!(guide_is_minimum(prop.guides[0]))
  assert_true!(guide_is_maximum(prop.guides[1]))
}
