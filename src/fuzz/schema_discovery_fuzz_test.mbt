///|
test "fuzz: schema discovery request json with seeded documents" {
  let seeds = [0, 1, 42, 999]
  for seed in seeds {
    let request = @schema_discovery.DiscoverSchemaRequest::{
      documents: [
        @schema_discovery.DiscoveryDocument::{
          id: generate_random_string(seed, 8),
          source: @schema_discovery.DiscoveryDocumentSource::{
            source_type: if seed % 2 == 0 {
              "text"
            } else {
              ""
            },
            media_type: Some("text/plain"),
            name: Some(generate_random_string(seed + 1, 6)),
            content: Some(generate_random_string(seed + 2, 24)),
            uri: None,
          },
          metadata: Some(
            Json::object({ "seed": Json::number(seed.to_double()) }),
          ),
        },
      ],
      hints: Some(@schema_discovery.DiscoveryHints::{
        language: Some("ja"),
        domain: Some("fuzz"),
        document_type: Some("invoice"),
        expected_schema_format: Some("json_schema"),
      }),
      options: Some(@schema_discovery.DiscoveryOptions::default()),
      existing_schema: Some(Json::object({ "type": Json::string("object") })),
    }
    let s = request.to_json().stringify()
    assert_true(s.contains("documents"))
    assert_true(s.contains("source"))
    assert_true(s.contains("existing_schema"))
  }
}

///|
test "fuzz: export_schema formats with odd candidates" {
  let formats = ["", "json_schema", "openapi_schema", "markdown_report", "unknown"]
  for format in formats {
    let nested : Map[String, Json] = {}
    nested["type"] = Json::string("object")
    let field_schema : Map[String, Json] = {}
    field_schema["type"] = Json::string("string")
    let properties : Map[String, Json] = {}
    properties[generate_random_string(format.length(), 3)] = Json::object(field_schema)
    nested["properties"] = Json::object(properties)
    let candidate : Map[String, Json] = {}
    candidate["id"] = Json::string("fuzz-schema")
    candidate["name"] = Json::string(generate_random_string(format.length() + 1, 8))
    candidate["version"] = Json::string("0.0.0")
    candidate["format"] = Json::string("json_schema")
    candidate["status"] = Json::string("candidate")
    candidate["schema"] = Json::object(nested)
    let response = @schema_discovery.export_schema(@schema_discovery.ExportSchemaRequest::{
      schema_candidate: Json::object(candidate),
      format,
      options: None,
    })
    assert_true!(response.content.length() > 0)
  }
}
