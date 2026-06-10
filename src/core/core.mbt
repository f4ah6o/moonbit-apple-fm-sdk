///|
pub enum UseCase {
  General
  ContentTagging
} derive(Eq, @debug.Debug)

///|
pub fn UseCase::to_int(self : UseCase) -> Int {
  match self {
    General => 0
    ContentTagging => 1
  }
}

///|
pub enum Guardrails {
  Default
  PermissiveContentTransformations
} derive(Eq, @debug.Debug)

///|
pub fn Guardrails::to_int(self : Guardrails) -> Int {
  match self {
    Default => 0
    PermissiveContentTransformations => 1
  }
}

///|
pub enum UnavailableReason {
  AppleIntelligenceNotEnabled
  DeviceNotEligible
  ModelNotReady
  Unknown
} derive(Eq, @debug.Debug)

///|
pub fn UnavailableReason::from_int(code : Int) -> UnavailableReason {
  match code {
    0 => AppleIntelligenceNotEnabled
    1 => DeviceNotEligible
    2 => ModelNotReady
    _ => Unknown
  }
}

///|
pub struct SystemLanguageModel {
  ptr : @ffi.FMSystemLanguageModelRef
}

///|
pub fn SystemLanguageModel::new(
  use_case~ : UseCase = General,
  guardrails~ : Guardrails = Default
) -> SystemLanguageModel {
  let ptr = @ffi.system_language_model_create(
    use_case.to_int(),
    guardrails.to_int(),
  )
  { ptr, }
}

///|
pub fn SystemLanguageModel::get_default() -> SystemLanguageModel {
  let ptr = @ffi.system_language_model_get_default()
  { ptr, }
}

///|
pub fn SystemLanguageModel::is_available(
  self : SystemLanguageModel
) -> (Bool, UnavailableReason?) {
  let (available, reason_code) = @ffi.system_language_model_is_available(
    self.ptr,
  )
  if available {
    (true, None)
  } else {
    (false, Some(UnavailableReason::from_int(reason_code)))
  }
}

///|
pub fn SystemLanguageModel::release(self : SystemLanguageModel) -> Unit {
  @ffi.release_model(self.ptr)
}
