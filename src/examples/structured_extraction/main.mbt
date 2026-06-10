///|
struct Receipt {
  merchant : String
  total : Double
  date : String
  items : Array[String]
} derive(FromJson, ToJson)

///|
impl @generable.Generable for Receipt with generation_schema() {
  @schema.GenerationSchema::new(
    "Receipt",
    description=Some("A purchase receipt"),
    properties=[
      @property.Property::new(
        "merchant",
        "String",
        description=Some("Merchant name"),
      ),
      @property.Property::new(
        "total",
        "Double",
        description=Some("Total amount"),
      ),
      @property.Property::new(
        "date",
        "String",
        description=Some("Purchase date, YYYY-MM-DD"),
      ),
      @property.Property::new(
        "items",
        "Array[String]",
        description=Some("Purchased item names"),
      ),
    ],
  )
}

///|
impl @generable.Generable for Receipt with from_generated_content(content) {
  content.decode()
}

///|
impl @generable.Generable for Receipt with to_generated_content(self) {
  @generable.GeneratedContent::from_json_string(self.to_json().stringify())
}

fn main {
  println("=== Structured Extraction Example ===\n")

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
    instructions=Some("Extract structured data from the user's text."),
  )
  defer session.release()
  let text = "Receipt: Blue Bottle Coffee, 2026-06-01. Latte $5.50, Croissant $4.25. Total $9.75."
  println("Input: \{text}")
  try {
    let receipt : Receipt = session.extract("Extract the receipt: \{text}")
    println("Merchant: \{receipt.merchant}")
    println("Total: \{receipt.total}")
    println("Date: \{receipt.date}")
    println("Items: \{receipt.items}")
  } catch {
    e => println("Error: \{e}")
  }
}
