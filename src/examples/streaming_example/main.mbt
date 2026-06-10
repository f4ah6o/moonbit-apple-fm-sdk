fn main {
  println("=== Streaming Response Example ===\n")

  // Check if the model is available
  let model = @core.SystemLanguageModel::new()
  defer model.release()
  let (available, reason) = model.is_available()
  if !available {
    println("Model not available")
    ignore(reason)
    return
  }

  // Create a session
  let session = @session.LanguageModelSession::new(
    instructions=Some("You are a helpful assistant."),
  )
  defer session.release()

  // Stream a response
  let prompt = "Tell me a short story about a cat."
  println("User: \{prompt}\n")
  println("Assistant:")
  try {
    let final_response = session.stream_response(prompt)
    println(final_response)
    println("")
  } catch {
    e => println("Error: \{e}")
  }
}
