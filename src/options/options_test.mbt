fn is_greedy(s : SamplingMode) -> Bool {
  match s.mode_type {
    Greedy => true
    _ => false
  }
}

fn is_random(s : SamplingMode) -> Bool {
  match s.mode_type {
    Random => true
    _ => false
  }
}

test "GenerationOptions default values" {
  let opts = GenerationOptions::new()
  assert_true!(opts.sampling.is_empty())
  assert_true!(opts.temperature.is_empty())
  assert_true!(opts.maximum_response_tokens.is_empty())
}

test "GenerationOptions with temperature" {
  let opts = GenerationOptions::new(temperature=Some(0.7))
  assert_true!(opts.temperature == Some(0.7))
  assert_true!(opts.sampling.is_empty())
  assert_true!(opts.maximum_response_tokens.is_empty())
}

test "GenerationOptions with max tokens" {
  let opts = GenerationOptions::new(maximum_response_tokens=Some(500))
  assert_true!(opts.maximum_response_tokens == Some(500))
  assert_true!(opts.temperature.is_empty())
  assert_true!(opts.sampling.is_empty())
}

test "GenerationOptions full config" {
  let sampling = SamplingMode::greedy()
  let opts = GenerationOptions::new(
    sampling=Some(sampling),
    temperature=Some(0.8),
    maximum_response_tokens=Some(1000),
  )
  assert_true!(opts.sampling.is_empty() == false)
  assert_true!(opts.temperature == Some(0.8))
  assert_true!(opts.maximum_response_tokens == Some(1000))
}

test "SamplingMode greedy" {
  let s = SamplingMode::greedy()
  assert_true!(is_greedy(s))
  assert_true!(s.top.is_empty())
  assert_true!(s.probability_threshold.is_empty())
  assert_true!(s.seed.is_empty())
}

test "SamplingMode random with seed only" {
  let s = SamplingMode::random(seed=Some(42))
  assert_true!(is_random(s))
  assert_true!(s.top.is_empty())
  assert_true!(s.probability_threshold.is_empty())
  assert_true!(s.seed == Some(42))
}

test "SamplingMode random with top" {
  let s = SamplingMode::random(top=Some(50), seed=Some(42))
  assert_true!(is_random(s))
  assert_true!(s.top == Some(50))
  assert_true!(s.probability_threshold.is_empty())
  assert_true!(s.seed == Some(42))
}

test "SamplingMode random with probability threshold" {
  let s = SamplingMode::random(probability_threshold=Some(0.9), seed=Some(42))
  assert_true!(is_random(s))
  assert_true!(s.top.is_empty())
  assert_true!(s.probability_threshold == Some(0.9))
  assert_true!(s.seed == Some(42))
}

test "SamplingMode random edge cases" {
  let s1 = SamplingMode::random(probability_threshold=Some(0.0))
  assert_true!(s1.probability_threshold == Some(0.0))
  let s2 = SamplingMode::random(probability_threshold=Some(1.0))
  assert_true!(s2.probability_threshold == Some(1.0))
  let s3 = SamplingMode::random(top=Some(1))
  assert_true!(s3.top == Some(1))
}

test "GenerationOptions to_json minimal" {
  let opts = GenerationOptions::new()
  let json = opts.to_json()
  assert_eq!(json.stringify(), "{}")
}

test "GenerationOptions to_json with temperature" {
  let opts = GenerationOptions::new(temperature=Some(0.7))
  let json = opts.to_json()
  let s = json.stringify()
  assert_true!(s.contains("temperature"))
  assert_true!(s.contains("0.7"))
}

test "GenerationOptions to_json with max tokens" {
  let opts = GenerationOptions::new(maximum_response_tokens=Some(500))
  let json = opts.to_json()
  let s = json.stringify()
  assert_true!(s.contains("maximum_response_tokens"))
  assert_true!(s.contains("500"))
}

test "GenerationOptions to_json with greedy sampling" {
  let opts = GenerationOptions::new(
    sampling=Some(SamplingMode::greedy()),
    temperature=Some(0.3),
  )
  let json = opts.to_json()
  let s = json.stringify()
  assert_true!(s.contains("sampling"))
  assert_true!(s.contains("greedy"))
  assert_true!(s.contains("temperature"))
}

test "GenerationOptions to_json with random sampling" {
  let opts = GenerationOptions::new(
    sampling=Some(SamplingMode::random(top=Some(100), seed=Some(123))),
    temperature=Some(0.75),
    maximum_response_tokens=Some(1000),
  )
  let json = opts.to_json()
  let s = json.stringify()
  assert_true!(s.contains("random"))
  assert_true!(s.contains("top_k"))
  assert_true!(s.contains("seed"))
  assert_true!(s.contains("temperature"))
  assert_true!(s.contains("maximum_response_tokens"))
}

test "GenerationOptions to_json random with probability threshold" {
  let opts = GenerationOptions::new(
    sampling=Some(SamplingMode::random(probability_threshold=Some(0.9))),
  )
  let json = opts.to_json()
  let s = json.stringify()
  assert_true!(s.contains("top_p"))
  assert_true!(s.contains("random"))
}

test "SamplingModeType equality" {
  let g = SamplingMode::greedy()
  let r = SamplingMode::random()
  assert_true!(g.mode_type == g.mode_type)
  assert_true!(r.mode_type == r.mode_type)
  assert_true!(g.mode_type != r.mode_type)
}
