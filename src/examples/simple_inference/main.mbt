fn main {
  let model = @core.SystemLanguageModel::new()
  defer model.release()
  let (available, reason) = model.is_available()
  if !available {
    println("Model not available")
    ignore(reason)
    return
  }
  println("Model is available")
  let session = @session.LanguageModelSession::new(
    instructions=Some("You are a helpful assistant."),
  )
  defer session.release()
  try {
    let response = session.respond("What is MoonBit?")
    println("Response: \{response}")
  } catch {
    e => println("Error: \{e}")
  }
}
