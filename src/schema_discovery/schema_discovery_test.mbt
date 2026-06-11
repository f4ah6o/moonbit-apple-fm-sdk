test "DiscoverSchemaRequest to_json uses schema discovery wire shape" {
  let request = DiscoverSchemaRequest::{
    documents: [
      DiscoveryDocument::{
        id: "doc-1",
        source: DiscoveryDocumentSource::{
          source_type: "text",
          media_type: None,
          name: None,
          content: Some("請求日 2026-01-01"),
          uri: None,
        },
        metadata: None,
      },
    ],
    hints: None,
    options: Some(DiscoveryOptions::default()),
    existing_schema: None,
  }
  let s = request.to_json().stringify()
  assert_true!(s.contains("documents"))
  assert_true!(s.contains("min_presence_rate_for_required"))
  assert_true!(s.contains("text"))
}

test "export_schema returns schema json" {
  let schema : Map[String, Json] = {}
  schema["type"] = Json::string("object")
  let candidate : Map[String, Json] = {}
  candidate["id"] = Json::string("schema-1")
  candidate["name"] = Json::string("Invoice")
  candidate["version"] = Json::string("0.1.0")
  candidate["format"] = Json::string("json_schema")
  candidate["status"] = Json::string("candidate")
  candidate["schema"] = Json::object(schema)
  let response = export_schema(ExportSchemaRequest::{
    schema_candidate: Json::object(candidate),
    format: "json_schema",
    options: None,
  })
  assert_true!(response.content.contains("object"))
}
