///|
pub enum SamplingModeType {
  Greedy
  Random
} derive(Eq, @debug.Debug)

///|
pub struct SamplingMode {
  mode_type : SamplingModeType
  top : Int?
  probability_threshold : Double?
  seed : Int?
} derive(@debug.Debug)

///|
pub fn SamplingMode::greedy() -> SamplingMode {
  { mode_type: Greedy, top: None, probability_threshold: None, seed: None }
}

///|
pub fn SamplingMode::random(
  top~ : Int? = None,
  probability_threshold~ : Double? = None,
  seed~ : Int? = None
) -> SamplingMode {
  { mode_type: Random, top, probability_threshold, seed }
}

///|
pub struct GenerationOptions {
  sampling : SamplingMode?
  temperature : Double?
  maximum_response_tokens : Int?
} derive(@debug.Debug)

///|
pub fn GenerationOptions::new(
  sampling~ : SamplingMode? = None,
  temperature~ : Double? = None,
  maximum_response_tokens~ : Int? = None
) -> GenerationOptions {
  { sampling, temperature, maximum_response_tokens }
}

///|
pub fn GenerationOptions::to_json(self : GenerationOptions) -> Json {
  let obj : Map[String, Json] = {}
  match self.sampling {
    Some(s) => {
      let sampling_obj : Map[String, Json] = {}
      match s.mode_type {
        Greedy => sampling_obj["mode"] = Json::string("greedy")
        Random => {
          sampling_obj["mode"] = Json::string("random")
          match s.top {
            Some(t) => sampling_obj["top_k"] = Json::string(t.to_string())
            None => ()
          }
          match s.probability_threshold {
            Some(p) => sampling_obj["top_p"] = Json::string(p.to_string())
            None => ()
          }
          match s.seed {
            Some(sd) => sampling_obj["seed"] = Json::string(sd.to_string())
            None => ()
          }
        }
      }
      obj["sampling"] = Json::object(sampling_obj)
    }
    None => ()
  }
  match self.temperature {
    Some(t) => obj["temperature"] = Json::number(t)
    None => ()
  }
  match self.maximum_response_tokens {
    Some(m) => obj["maximum_response_tokens"] = Json::number(m.to_double())
    None => ()
  }
  Json::object(obj)
}
