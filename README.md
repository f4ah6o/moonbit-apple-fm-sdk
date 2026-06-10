# MoonBit Apple Foundation Models SDK

MoonBit bindings for Apple's [Foundation Models](https://developer.apple.com/documentation/foundationmodels) framework — run the on-device language model that powers Apple Intelligence, directly from MoonBit.

## Requirements

- macOS 26+ on Apple Silicon with Apple Intelligence enabled
- [MoonBit toolchain](https://www.moonbitlang.com/download/) (native target)
- The `foundation-models-c` C bindings library (from [python-apple-fm-sdk](../python-apple-fm-sdk)), built at
  `../python-apple-fm-sdk/foundation-models-c/.build/release`

> The link path to `libFoundationModels.dylib` is currently hardcoded in each
> `moon.pkg.json` (`link.native.cc-link-flags`). Adjust it if your checkout
> lives elsewhere.

## Quick start

```moonbit
fn main {
  let model = @core.SystemLanguageModel::new()
  defer model.release()
  let (available, _) = model.is_available()
  if !available {
    println("Model not available")
    return
  }
  let session = @session.LanguageModelSession::new(
    instructions=Some("You are a helpful assistant."),
  )
  defer session.release()
  let response = session.respond("What is the capital of France?")
  println(response)
}
```

Run an example:

```sh
moon run src/examples/simple_inference --target native
```

## Structured output → MoonBit types

Model output can be mapped directly into your own structs. Define a struct
with `derive(FromJson)`, implement the `Generable` trait (schema + two
one-liners), and call `session.extract`:

```moonbit
struct Receipt {
  merchant : String
  total : Double
  date : String
  items : Array[String]
} derive(FromJson, ToJson)

impl @generable.Generable for Receipt with generation_schema() {
  @schema.GenerationSchema::new(
    "Receipt",
    description=Some("A purchase receipt"),
    properties=[
      @property.Property::new("merchant", "String", description=Some("Merchant name")),
      @property.Property::new("total", "Double", description=Some("Total amount")),
      @property.Property::new("date", "String", description=Some("Purchase date, YYYY-MM-DD")),
      @property.Property::new("items", "Array[String]", description=Some("Purchased item names")),
    ],
  )
}

impl @generable.Generable for Receipt with from_generated_content(content) {
  content.decode()
}

impl @generable.Generable for Receipt with to_generated_content(self) {
  @generable.GeneratedContent::from_json_string(self.to_json().stringify())
}

fn main {
  let session = @session.LanguageModelSession::new()
  defer session.release()
  let receipt : Receipt = session.extract(
    "Extract the receipt: Blue Bottle Coffee, 2026-06-01. Latte $5.50. Total $5.50.",
  )
  println("\{receipt.merchant}: \{receipt.total}")
}
```

Alternatively, skip the `Generable` impl and pass a raw JSON schema —
`T` only needs `derive(FromJson)`:

```moonbit
let receipt : Receipt = session.extract_with_json_schema(prompt, json_schema)
```

Notes:

- `Int64`/`UInt64` decode from string-encoded JSON values; prefer `Int`/`Double`
  for model output fields.
- Optional fields should be `T?` and marked `is_optional=true` in the schema.
  With `derive(FromJson)`, a missing key decodes to `None`, but an explicit
  JSON `null` fails to decode.

See [src/examples/structured_extraction](src/examples/structured_extraction) for the full example.

## API overview

| Package | Contents |
|---|---|
| `core` | `SystemLanguageModel`, `UseCase`, `Guardrails`, availability checks |
| `session` | `LanguageModelSession` — `respond`, `stream_response`, `respond_with_schema`, `respond_with_json_schema`, `extract`, `extract_with_json_schema` |
| `schema` | `GenerationSchema` — structured output schema definition |
| `property` | `Property` — schema field definition |
| `guide` | `GenerationGuide` — field constraints (enum, regex, range, …) |
| `generable` | `GeneratedContent`, `Generable` trait, `decode` |
| `options` | `GenerationOptions`, sampling mode, temperature |
| `prompt` | Prompt composition (text, images) |
| `tool` | `Tool` trait for function calling |
| `transcript` | Session history management |
| `errors` | `GenerationError` and friends |

## Examples

| Example | Run |
|---|---|
| Basic inference | `moon run src/examples/simple_inference --target native` |
| Streaming | `moon run src/examples/streaming_example --target native` |
| Structured extraction | `moon run src/examples/structured_extraction --target native` |
| Transcript processing | `moon run src/examples/transcript_processing --target native` |

## Development

```sh
moon check                 # type-check everything
moon test --target native  # run tests (requires the C library; model not needed)
```
