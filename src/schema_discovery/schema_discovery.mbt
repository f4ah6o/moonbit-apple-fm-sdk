///|
pub(all) struct DiscoverSchemaRequest {
  documents : Array[DiscoveryDocument]
  hints : DiscoveryHints?
  options : DiscoveryOptions?
  existing_schema : Json?
}

///|
pub(all) struct DiscoveryDocument {
  id : String
  source : DiscoveryDocumentSource
  metadata : Json?
}

///|
pub(all) struct DiscoveryDocumentSource {
  source_type : String
  media_type : String?
  name : String?
  content : String?
  uri : String?
}

///|
pub(all) struct DiscoveryHints {
  language : String?
  domain : String?
  document_type : String?
  expected_schema_format : String?
}

///|
pub(all) struct DiscoveryOptions {
  include_evidence : Bool
  include_layout : Bool
  include_raw_extractions : Bool
  min_presence_rate_for_required : Double
  min_confidence : Double
  max_field_candidates : Int
  merge_similar_fields : Bool
  infer_constraints : Bool
  infer_arrays : Bool
  infer_nested_objects : Bool
}

///|
pub(all) struct DiscoverSchemaResponse {
  raw : Json
}

///|
pub(all) struct ExportSchemaRequest {
  schema_candidate : Json
  format : String
  options : Json?
}

///|
pub(all) struct ExportSchemaResponse {
  format : String
  content : String
}

///|
pub fn DiscoveryOptions::default() -> DiscoveryOptions {
  {
    include_evidence: true,
    include_layout: true,
    include_raw_extractions: false,
    min_presence_rate_for_required: 0.8,
    min_confidence: 0.5,
    max_field_candidates: 200,
    merge_similar_fields: true,
    infer_constraints: true,
    infer_arrays: true,
    infer_nested_objects: true,
  }
}

///|
pub fn DiscoverSchemaResponse::json(self : DiscoverSchemaResponse) -> Json {
  self.raw
}

///|
pub fn discover_schema(
  session : @session.LanguageModelSession,
  request : DiscoverSchemaRequest,
  options~ : @options.GenerationOptions? = None
) -> DiscoverSchemaResponse raise {
  let prompt = build_discovery_prompt(request)
  let content = session.respond_with_json_schema(
    prompt,
    discovery_response_schema_json(),
    options~,
  )
  defer content.release()
  { raw: content.json() }
}

///|
pub fn export_schema(request : ExportSchemaRequest) -> ExportSchemaResponse {
  let content = match request.format {
    "markdown_report" => markdown_schema_report(request.schema_candidate)
    _ => schema_json_from_candidate(request.schema_candidate).stringify()
  }
  { format: request.format, content }
}

///|
pub fn DiscoverSchemaRequest::to_json(self : DiscoverSchemaRequest) -> Json {
  let obj : Map[String, Json] = {}
  obj["documents"] = Json::array(self.documents.map(DiscoveryDocument::to_json))
  match self.hints {
    Some(h) => obj["hints"] = h.to_json()
    None => ()
  }
  match self.options {
    Some(o) => obj["options"] = o.to_json()
    None => ()
  }
  match self.existing_schema {
    Some(s) => obj["existing_schema"] = s
    None => ()
  }
  Json::object(obj)
}

///|
pub fn DiscoveryDocument::to_json(self : DiscoveryDocument) -> Json {
  let obj : Map[String, Json] = {}
  obj["id"] = Json::string(self.id)
  obj["source"] = self.source.to_json()
  match self.metadata {
    Some(m) => obj["metadata"] = m
    None => ()
  }
  Json::object(obj)
}

///|
pub fn DiscoveryDocumentSource::to_json(
  self : DiscoveryDocumentSource
) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string(self.source_type)
  set_string(obj, "media_type", self.media_type)
  set_string(obj, "name", self.name)
  set_string(obj, "content", self.content)
  set_string(obj, "uri", self.uri)
  Json::object(obj)
}

///|
pub fn DiscoveryHints::to_json(self : DiscoveryHints) -> Json {
  let obj : Map[String, Json] = {}
  set_string(obj, "language", self.language)
  set_string(obj, "domain", self.domain)
  set_string(obj, "document_type", self.document_type)
  set_string(obj, "expected_schema_format", self.expected_schema_format)
  Json::object(obj)
}

///|
pub fn DiscoveryOptions::to_json(self : DiscoveryOptions) -> Json {
  let obj : Map[String, Json] = {}
  obj["include_evidence"] = Json::boolean(self.include_evidence)
  obj["include_layout"] = Json::boolean(self.include_layout)
  obj["include_raw_extractions"] = Json::boolean(self.include_raw_extractions)
  obj["min_presence_rate_for_required"] = Json::number(
    self.min_presence_rate_for_required,
  )
  obj["min_confidence"] = Json::number(self.min_confidence)
  obj["max_field_candidates"] = Json::number(
    self.max_field_candidates.to_double(),
  )
  obj["merge_similar_fields"] = Json::boolean(self.merge_similar_fields)
  obj["infer_constraints"] = Json::boolean(self.infer_constraints)
  obj["infer_arrays"] = Json::boolean(self.infer_arrays)
  obj["infer_nested_objects"] = Json::boolean(self.infer_nested_objects)
  Json::object(obj)
}

///|
pub fn discovery_response_schema_json() -> String {
  let root : Map[String, Json] = {}
  root["$schema"] = Json::string("https://json-schema.org/draft/2020-12/schema")
  root["type"] = Json::string("object")
  root["additionalProperties"] = Json::boolean(false)
  root["required"] = Json::array([
    Json::string("schema_candidate"),
    Json::string("field_candidates"),
    Json::string("document_summaries"),
    Json::string("conflicts"),
    Json::string("warnings"),
    Json::string("review_findings"),
    Json::string("metrics"),
  ])
  let props : Map[String, Json] = {}
  props["schema_candidate"] = simple_schema("object")
  props["field_candidates"] = array_schema("object")
  props["document_summaries"] = array_schema("object")
  props["conflicts"] = array_schema("object")
  props["warnings"] = array_schema("object")
  props["review_findings"] = array_schema("object")
  props["metrics"] = simple_schema("object")
  props["schema_diff"] = simple_schema("object")
  root["properties"] = Json::object(props)
  Json::object(root).stringify()
}

fn build_discovery_prompt(request : DiscoverSchemaRequest) -> String {
  "Discover a reusable schema candidate from the provided documents.\n" +
  "Treat every result as a candidate, not an approved schema.\n" +
  "Return only data that matches the supplied JSON Schema.\n" +
  "Preserve evidence only when requested. Mark ambiguous or low-confidence fields for review.\n" +
  "Do not add raw document text to warnings or logs unless it is evidence requested by the caller.\n\n" +
  "Request JSON:\n" + request.to_json().stringify()
}

fn set_string(obj : Map[String, Json], key : String, value : String?) -> Unit {
  match value {
    Some(v) => obj[key] = Json::string(v)
    None => ()
  }
}

fn simple_schema(kind : String) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string(kind)
  Json::object(obj)
}

fn array_schema(item_kind : String) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string("array")
  obj["items"] = simple_schema(item_kind)
  Json::object(obj)
}

fn schema_json_from_candidate(candidate : Json) -> Json {
  match candidate {
    Object(obj) =>
      match obj.get("schema") {
        Some(schema) => schema
        None => Json::object({})
      }
    _ => Json::object({})
  }
}

fn markdown_schema_report(candidate : Json) -> String {
  match candidate {
    Object(obj) => {
      let name = json_string(obj, "name").unwrap_or("DiscoveredDocumentSchema")
      let id = json_string(obj, "id").unwrap_or("")
      let version = json_string(obj, "version").unwrap_or("")
      let format = json_string(obj, "format").unwrap_or("")
      let status = json_string(obj, "status").unwrap_or("")
      "# Schema Candidate: \{name}\n\n- ID: \{id}\n- Version: \{version}\n- Format: \{format}\n- Status: \{status}\n"
    }
    _ => "# Schema Candidate\n"
  }
}

fn json_string(obj : Map[String, Json], key : String) -> String? {
  match obj.get(key) {
    Some(String(s)) => Some(s)
    _ => None
  }
}
