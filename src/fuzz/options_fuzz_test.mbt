///|
test "fuzz: GenerationOptions with seeded boundary values" {
  let temperatures = [-1.0, 0.0, 0.7, 1.0, 999.0]
  let token_limits = [-1, 0, 1, 1024, 2147483647]
  let seeds = [-1, 0, 1, 42, 2147483647]
  for temp in temperatures {
    for max_tokens in token_limits {
      for seed in seeds {
        let opts = @options.GenerationOptions::new(
          sampling=Some(
            @options.SamplingMode::random(
              top=Some(max_tokens),
              probability_threshold=Some(temp),
              seed=Some(seed),
            ),
          ),
          temperature=Some(temp),
          maximum_response_tokens=Some(max_tokens),
        )
        let s = opts.to_json().stringify()
        assert_true(s.contains("sampling"))
        assert_true(s.contains("temperature"))
        assert_true(s.contains("maximum_response_tokens"))
      }
    }
  }
}

///|
test "fuzz: GenerationOptions random sampling variants" {
  let opts = [
    @options.GenerationOptions::new(
      sampling=Some(@options.SamplingMode::greedy()),
    ),
    @options.GenerationOptions::new(
      sampling=Some(@options.SamplingMode::random(top=Some(1))),
    ),
    @options.GenerationOptions::new(
      sampling=Some(
        @options.SamplingMode::random(probability_threshold=Some(0.0)),
      ),
    ),
    @options.GenerationOptions::new(
      sampling=Some(
        @options.SamplingMode::random(probability_threshold=Some(1.0)),
      ),
    ),
  ]
  for opt in opts {
    let s = opt.to_json().stringify()
    assert_true(s.contains("sampling"))
  }
}
