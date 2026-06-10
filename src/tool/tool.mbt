///|
pub(open) trait Tool {
  name(Self) -> String
  description(Self) -> String
  arguments_schema(Self) -> @schema.GenerationSchema
  call(Self, @generable.GeneratedContent) -> String raise
}

///|
pub struct BridgedTool {
  ptr : @ffi.FMBridgedToolRef
}

///|
pub fn[T : Tool] BridgedTool::create(tool : T) -> BridgedTool raise {
  let name_bytes = @ffi.string_to_utf8_bytes(tool.name())
  let desc_bytes = @ffi.string_to_utf8_bytes(tool.description())
  let schema = tool.arguments_schema()
  let (ptr, error_code) = @ffi.tool_create(name_bytes, desc_bytes, schema.ptr)
  if error_code != 0 {
    @errors.raise_generation_error(error_code, "Failed to create bridged tool")
  }
  { ptr, }
}

///|
pub fn BridgedTool::release(self : BridgedTool) -> Unit {
  @ffi.release_tool(self.ptr)
  @ffi.tool_cleanup()
}
