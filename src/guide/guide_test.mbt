fn is_guide_type(g : GenerationGuide, expected : String) -> Bool {
  match (g.guide_type, expected) {
    (AnyOf, "AnyOf") => true
    (Constant, "Constant") => true
    (Count, "Count") => true
    (Element, "Element") => true
    (MaxItems, "MaxItems") => true
    (Maximum, "Maximum") => true
    (MinItems, "MinItems") => true
    (Minimum, "Minimum") => true
    (Range, "Range") => true
    (Regex, "Regex") => true
    _ => false
  }
}

fn is_inner_guide_type(g : GenerationGuide, expected : String) -> Bool {
  match g.inner_guide {
    Some(inner) => is_guide_type(inner, expected)
    None => false
  }
}

test "GenerationGuide anyOf creation" {
  let g = GenerationGuide::any_of(["red", "green", "blue"])
  assert_true!(is_guide_type(g, "AnyOf"))
  assert_true!(g.string_values.length() == 3)
  assert_true!(g.string_values[0] == "red")
  assert_true!(g.string_values[1] == "green")
  assert_true!(g.string_values[2] == "blue")
}

test "GenerationGuide constant creation" {
  let g = GenerationGuide::constant("fixed_value")
  assert_true!(is_guide_type(g, "Constant"))
  assert_true!(g.string_values.length() == 1)
  assert_true!(g.string_values[0] == "fixed_value")
}

test "GenerationGuide count creation" {
  let g = GenerationGuide::count(5)
  assert_true!(is_guide_type(g, "Count"))
  assert_true!(g.int_value == 5)
}

test "GenerationGuide element creation with range inner" {
  let inner = GenerationGuide::range(1.0, 10.0)
  let g = GenerationGuide::element(inner)
  assert_true!(is_guide_type(g, "Element"))
  assert_true!(is_inner_guide_type(g, "Range"))
  match g.inner_guide {
    Some(inner_g) => {
      assert_true!(inner_g.double_value == 1.0)
      assert_true!(inner_g.double_value2 == 10.0)
    }
    None => assert_true!(false)
  }
}

test "GenerationGuide max_items creation" {
  let g = GenerationGuide::max_items(10)
  assert_true!(is_guide_type(g, "MaxItems"))
  assert_true!(g.int_value == 10)
}

test "GenerationGuide maximum creation" {
  let g = GenerationGuide::maximum(100.0)
  assert_true!(is_guide_type(g, "Maximum"))
  assert_true!(g.double_value == 100.0)
}

test "GenerationGuide min_items creation" {
  let g = GenerationGuide::min_items(2)
  assert_true!(is_guide_type(g, "MinItems"))
  assert_true!(g.int_value == 2)
}

test "GenerationGuide minimum creation" {
  let g = GenerationGuide::minimum(0.0)
  assert_true!(is_guide_type(g, "Minimum"))
  assert_true!(g.double_value == 0.0)
}

test "GenerationGuide range creation" {
  let g = GenerationGuide::range(0.99, 999.99)
  assert_true!(is_guide_type(g, "Range"))
  assert_true!(g.double_value == 0.99)
  assert_true!(g.double_value2 == 999.99)
}

test "GenerationGuide regex creation" {
  let g = GenerationGuide::regex("^[A-Z]{2}-[0-9]{4}$")
  assert_true!(is_guide_type(g, "Regex"))
  assert_true!(g.string_values.length() == 1)
  assert_true!(g.string_values[0] == "^[A-Z]{2}-[0-9]{4}$")
}

test "GenerationGuide element with anyOf inner" {
  let inner = GenerationGuide::any_of(["tech", "home", "sports"])
  let g = GenerationGuide::element(inner)
  assert_true!(is_guide_type(g, "Element"))
  assert_true!(is_inner_guide_type(g, "AnyOf"))
  match g.inner_guide {
    Some(inner_g) => assert_true!(inner_g.string_values.length() == 3)
    None => assert_true!(false)
  }
}

test "GenerationGuide element with minimum inner" {
  let inner = GenerationGuide::minimum(0.01)
  let g = GenerationGuide::element(inner)
  assert_true!(is_guide_type(g, "Element"))
  assert_true!(is_inner_guide_type(g, "Minimum"))
  match g.inner_guide {
    Some(inner_g) => assert_true!(inner_g.double_value == 0.01)
    None => assert_true!(false)
  }
}

test "GenerationGuide default values are zeroed" {
  let g = GenerationGuide::any_of(["a"])
  assert_true!(g.int_value == 0)
  assert_true!(g.double_value == 0.0)
  assert_true!(g.double_value2 == 0.0)
  match g.inner_guide {
    None => ()
    Some(_) => assert_true!(false)
  }
}

test "GuideType equality" {
  let g1 = GenerationGuide::any_of(["a"])
  let g2 = GenerationGuide::range(0.0, 1.0)
  let g3 = GenerationGuide::any_of(["b"])
  assert_true!(g1.guide_type == g3.guide_type)
  assert_true!(g1.guide_type != g2.guide_type)
}
