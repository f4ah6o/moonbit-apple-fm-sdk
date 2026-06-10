fn main {
  println("=== Simple Inference Example ===\n")

  // Check if the model is available
  let model = @core.SystemLanguageModel::new()
  defer model.release()
  let (available, reason) = model.is_available()
  if !available {
    println("Model not available")
    ignore(reason)
    return
  }

  // Create a session with instructions
  let session = @session.LanguageModelSession::new(
    instructions=Some("You are a helpful assistant that provides concise answers."),
  )
  defer session.release()

  // Send a prompt and get a response
  let prompt = "What is the capital of France?"
  println("User: \{prompt}")
  try {
    let response = session.respond(prompt)
    println("Assistant: \{response}\n")
  } catch {
    e => {
      println("Error: \{e}")
      return
    }
  }

  // Continue the session
  let follow_up = "What is its population?"
  println("User: \{follow_up}")
  try {
    let response = session.respond(follow_up)
    println("Assistant: \{response}\n")
  } catch {
    e => println("Error: \{e}")
  }
}
