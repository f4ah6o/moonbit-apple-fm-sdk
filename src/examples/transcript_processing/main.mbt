/// Get a string value from a Json object by key.
fn json_get_string(obj : Json, key : String) -> String? {
  match obj {
    Object(map) =>
      match map.get(key) {
        Some(String(s)) => Some(s)
        _ => None
      }
    _ => None
  }
}

/// Get an array value from a Json object by key.
fn json_get_array(obj : Json, key : String) -> Array[Json]? {
  match obj {
    Object(map) =>
      match map.get(key) {
        Some(Array(arr)) => Some(arr)
        _ => None
      }
    _ => None
  }
}

/// Get an object value from a Json object by key.
fn json_get_object(obj : Json, key : String) -> Json? {
  match obj {
    Object(map) => map.get(key)
    _ => None
  }
}

/// Extract text from a contents JSON array.
fn extract_text_from_contents(contents : Array[Json]) -> String {
  let parts : Array[String] = []
  for content in contents {
    match json_get_string(content, "type") {
      Some("text") =>
        match json_get_string(content, "text") {
          Some(t) => parts.push(t)
          None => ()
        }
      Some("structure") =>
        match json_get_object(content, "structure") {
          Some(s) => parts.push(s.stringify())
          None => ()
        }
      _ => ()
    }
  }
  parts.join(" ")
}

/// Get entries from a transcript JSON object.
fn get_entries(transcript : Json) -> Array[Json] {
  match json_get_object(transcript, "transcript") {
    Some(t) =>
      match json_get_array(t, "entries") {
        Some(entries) => entries
        None => []
      }
    None => []
  }
}

/// Get the role string from an entry.
fn get_role(entry : Json) -> String {
  match json_get_string(entry, "role") {
    Some(r) => r
    None => "unknown"
  }
}

/// Get contents array from an entry.
fn get_contents(entry : Json) -> Array[Json] {
  match json_get_array(entry, "contents") {
    Some(c) => c
    None => []
  }
}

/// Analyze a transcript and print statistics.
fn analyze_transcript(transcript : Json) -> Unit {
  let entries = get_entries(transcript)
  let mut instructions_count = 0
  let mut user_count = 0
  let mut response_count = 0
  let mut tool_count = 0
  let mut total_user_chars = 0
  let mut total_response_chars = 0
  let mut tool_calls_count = 0
  let mut has_structured_output = false

  for entry in entries {
    let role = get_role(entry)
    if role == "instructions" {
      instructions_count += 1
    } else if role == "user" {
      user_count += 1
      let text = extract_text_from_contents(get_contents(entry))
      total_user_chars += text.length()
      match json_get_object(entry, "responseFormat") {
        Some(_) => has_structured_output = true
        None => ()
      }
    } else if role == "response" {
      response_count += 1
      let text = extract_text_from_contents(get_contents(entry))
      total_response_chars += text.length()
      match json_get_array(entry, "toolCalls") {
        Some(calls) => tool_calls_count += calls.length()
        None => ()
      }
    } else if role == "tool" {
      tool_count += 1
    }
  }

  println("============================================================")
  println("TRANSCRIPT SUMMARY")
  println("============================================================")

  match json_get_string(transcript, "type") {
    Some(t) => println("\nType: \{t}")
    None => ()
  }

  println("\nEntry Statistics:")
  println("  Total entries: \{entries.length()}")
  println("  Instructions entries: \{instructions_count}")
  println("  User entries: \{user_count}")
  println("  Response entries: \{response_count}")
  println("  Tool entries: \{tool_count}")

  println("\nContent Statistics:")
  println("  Total user characters: \{total_user_chars}")
  println("  Total response characters: \{total_response_chars}")
  if user_count > 0 {
    let avg = total_user_chars / user_count
    println("  Avg user entry length: \{avg} chars")
  }
  if response_count > 0 {
    let avg = total_response_chars / response_count
    println("  Avg response entry length: \{avg} chars")
  }
  if tool_calls_count > 0 {
    println("\nTool Usage:")
    println("  Tool calls made: \{tool_calls_count}")
  }
  if has_structured_output {
    println("\nStructured Output: Yes (JSON Schema)")
  }
  println("============================================================")
}

/// Print first N entries from a transcript.
fn print_transcript_entries(transcript : Json, max_entries : Int) -> Unit {
  let entries = get_entries(transcript)
  let count = if entries.length() < max_entries {
    entries.length()
  } else {
    max_entries
  }
  println("\nFirst \{count} entries:")
  println("------------------------------------------------------------")

  for i = 0; i < count; i = i + 1 {
    let entry = entries[i]
    let role = get_role(entry)
    println("\n[\{i + 1}] \{role}")

    let contents = get_contents(entry)
    if contents.length() > 0 {
      let text = extract_text_from_contents(contents)
      if text.length() > 0 {
        let display = if text.length() > 100 {
          text.substring(end=100) + "..."
        } else {
          text
        }
        println("    Content: \{display}")
      }
    }
  }

  if entries.length() > max_entries {
    let remaining = entries.length() - max_entries
    println("\n... and \{remaining} more entries")
  }
  println("------------------------------------------------------------")
}

fn main {
  println("Example: Processing Transcripts from Swift Apps\n")
  println("This demonstrates how to analyze session data exported from")
  println("your Swift app using the Foundation Models Framework.\n")

  // Example transcript JSON (normally loaded from file)
  let sample_transcript =
    #|{"version":1,"type":"FoundationModels.Transcript","transcript":{"entries":[{"role":"instructions","id":"instr-001","contents":[{"type":"text","text":"You are a helpful assistant."}]},{"role":"user","id":"user-001","contents":[{"type":"text","text":"What is the capital of France?"}]},{"role":"response","id":"resp-001","contents":[{"type":"text","text":"The capital of France is Paris."}]},{"role":"user","id":"user-002","contents":[{"type":"text","text":"What is its population?"}]},{"role":"response","id":"resp-002","contents":[{"type":"text","text":"Paris has a population of approximately 2.1 million in the city proper."}]}]}}
  let transcript = try { @json.parse(sample_transcript) } catch { _ => return }

  println("Analyzing transcript...")
  analyze_transcript(transcript)

  print_transcript_entries(transcript, 5)

  println("\nNext steps:")
  println("1. Export transcripts from your Swift app")
  println("2. Load and parse the JSON")
  println("3. Analyze with analyze_transcript()")
  println("4. Use insights to improve your app's features")
}
