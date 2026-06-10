///|
#borrow(object)
extern "c" fn fm_retain(object : FMSystemLanguageModelRef) = "FMRetain"

///|
extern "c" fn fm_release_model(object : FMSystemLanguageModelRef) = "FMRelease"

///|
extern "c" fn fm_release_session(
  object : FMLanguageModelSessionRef
) = "FMRelease"

///|
extern "c" fn fm_release_schema(object : FMGenerationSchemaRef) = "FMRelease"

///|
extern "c" fn fm_release_content(object : FMGeneratedContentRef) = "FMRelease"

///|
extern "c" fn fm_release_property(
  object : FMGenerationSchemaPropertyRef
) = "FMRelease"

///|
extern "c" fn fm_release_tool(object : FMBridgedToolRef) = "FMRelease"

///|
extern "c" fn fm_release_stream(
  object : FMLanguageModelSessionResponseStreamRef
) = "FMRelease"

///|
extern "c" fn fm_release_task(object : FMTaskRef) = "FMRelease"

///|
extern "c" fn fm_release_prompt(object : FMComposedPromptRef) = "FMRelease"

///|
extern "c" fn fm_task_cancel(task : FMTaskRef) = "FMTaskCancel"

///|
#external
type CString

///|
extern "c" fn fm_free_string(str : CString) = "FMFreeString"

///|
pub fn release_model(ptr : FMSystemLanguageModelRef) -> Unit {
  fm_release_model(ptr)
}

///|
pub fn release_session(ptr : FMLanguageModelSessionRef) -> Unit {
  fm_release_session(ptr)
}

///|
pub fn release_schema(ptr : FMGenerationSchemaRef) -> Unit {
  fm_release_schema(ptr)
}

///|
pub fn release_content(ptr : FMGeneratedContentRef) -> Unit {
  fm_release_content(ptr)
}

///|
pub fn release_property(ptr : FMGenerationSchemaPropertyRef) -> Unit {
  fm_release_property(ptr)
}

///|
pub fn release_task(ptr : FMTaskRef) -> Unit {
  fm_release_task(ptr)
}

///|
pub fn release_prompt(ptr : FMComposedPromptRef) -> Unit {
  fm_release_prompt(ptr)
}

///|
pub fn release_stream(
  ptr : FMLanguageModelSessionResponseStreamRef
) -> Unit {
  fm_release_stream(ptr)
}

///|
pub fn release_tool(ptr : FMBridgedToolRef) -> Unit {
  fm_release_tool(ptr)
}

///|
pub fn cancel_task(ptr : FMTaskRef) -> Unit {
  fm_task_cancel(ptr)
}

///|
pub fn free_string(str : CString) -> Unit {
  fm_free_string(str)
}
