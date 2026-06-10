///|
/// Smoke test for schema-constrained snapshot streaming.
/// Each snapshot is the full cumulative partial JSON of the Dashboard.
fn main {
  println("=== Structured Streaming Example ===\n")
  let model = @core.SystemLanguageModel::new()
  let (available, reason) = model.is_available()
  if !available {
    println("Model not available")
    ignore(reason)
    return
  }
  let session = @session.LanguageModelSession::new(
    instructions=Some(
      "You generate dashboard UI definitions. Respond in the same language as the user's request.",
    ),
  )
  let schema = @ui_ast.dashboard_schema()
  let mut count = 0
  try {
    let final_json = session.stream_response_with_schema(
      "今月の進捗をまとめて。タスク完了率、週ごとの完了タスク数の棒グラフ、残課題リストを含めて。",
      schema,
      on_snapshot=fn(snapshot) {
        count += 1
        println("--- snapshot \{count} (\{snapshot.length()} chars) ---")
        println(snapshot)
      },
    )
    println("\n=== \{count} snapshots received ===")
    let dashboard = @ui_ast.PartialDashboard::from_json(@json.parse(final_json))
    println("Decoded final dashboard:")
    println(dashboard)
  } catch {
    e => println("Error: \{e}")
  }
  schema.release()
  session.release()
}
