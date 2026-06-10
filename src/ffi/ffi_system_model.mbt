///|
extern "c" fn fm_system_language_model_create(
  use_case : Int,
  guardrails : Int
) -> FMSystemLanguageModelRef = "FMSystemLanguageModelCreate"

///|
extern "c" fn fm_system_language_model_get_default() -> FMSystemLanguageModelRef = "FMSystemLanguageModelGetDefault"

///|
#borrow(model, unavailable_reason)
extern "c" fn fm_system_language_model_is_available(
  model : FMSystemLanguageModelRef,
  unavailable_reason : Bytes
) -> Bool = "FMSystemLanguageModelIsAvailable"

///|
pub fn system_language_model_create(
  use_case : Int,
  guardrails : Int
) -> FMSystemLanguageModelRef {
  fm_system_language_model_create(use_case, guardrails)
}

///|
pub fn system_language_model_get_default() -> FMSystemLanguageModelRef {
  fm_system_language_model_get_default()
}

///|
pub fn system_language_model_is_available(
  model : FMSystemLanguageModelRef
) -> (Bool, Int) {
  let reason_buf = Bytes::new(4)
  let available = fm_system_language_model_is_available(model, reason_buf)
  let reason = reason_buf[0].to_int()
  (available, reason)
}
