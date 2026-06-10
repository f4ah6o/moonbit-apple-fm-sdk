///|
/// UI AST for the generative-dashboard demo.
///
/// The schema is a shallow discriminated union (no recursion): a Dashboard
/// holds a flat list of Sections, and each Section declares its `kind` plus
/// kind-specific optional fields. The on-device model is small, so the schema
/// is kept flat and every property carries a description telling the model
/// which kind uses it.

///|
pub fn section_schema() -> @schema.GenerationSchema {
  @schema.GenerationSchema::new(
    "Section",
    description=Some(
      "One dashboard section. kind selects the layout; fill only the fields for that kind.",
    ),
    properties=[
      @property.Property::new(
        "kind",
        "String",
        description=Some(
          "Section layout: 'text' (paragraph), 'metric' (single big number), 'bar_chart' (bar chart), 'list' (bullet list)",
        ),
        guides=[
          @guide.GenerationGuide::any_of(["text", "metric", "bar_chart", "list"]),
        ],
      ),
      @property.Property::new(
        "title",
        "String",
        description=Some("Short heading shown above the section"),
      ),
      @property.Property::new(
        "text",
        "String",
        description=Some("Body paragraph. Only for kind=text"),
        is_optional=true,
      ),
      @property.Property::new(
        "value",
        "String",
        description=Some("The headline number, e.g. '87'. Only for kind=metric"),
        is_optional=true,
      ),
      @property.Property::new(
        "unit",
        "String",
        description=Some("Unit or suffix for the metric, e.g. '%' or '件'. Only for kind=metric"),
        is_optional=true,
      ),
      @property.Property::new(
        "items",
        "Array[String]",
        description=Some("Bullet list entries. Only for kind=list"),
        is_optional=true,
      ),
      @property.Property::new(
        "labels",
        "Array[String]",
        description=Some("X-axis labels, one per bar. Only for kind=bar_chart"),
        is_optional=true,
      ),
      @property.Property::new(
        "values",
        "Array[Double]",
        description=Some(
          "Bar heights, same length and order as labels. Only for kind=bar_chart",
        ),
        is_optional=true,
      ),
    ],
  )
}

///|
pub fn dashboard_schema() -> @schema.GenerationSchema {
  @schema.GenerationSchema::new(
    "Dashboard",
    description=Some("A dashboard answering the user's request"),
    properties=[
      @property.Property::new(
        "title",
        "String",
        description=Some("Dashboard title summarizing the topic"),
      ),
      @property.Property::new(
        "sections",
        "Array[Section]",
        description=Some("3 to 5 sections, mixing different kinds"),
        guides=[@guide.GenerationGuide::max_items(5)],
      ),
    ],
    reference_schemas=[section_schema()],
  )
}

///|
/// Tolerant mirror of a Section for partial snapshots: every scalar is an
/// Option, arrays default to empty, unknown fields are ignored.
pub struct PartialSection {
  kind : String?
  title : String?
  text : String?
  value : String?
  unit : String?
  items : Array[String]
  labels : Array[String]
  values : Array[Double]
} derive(Show)

///|
pub struct PartialDashboard {
  title : String?
  sections : Array[PartialSection]
} derive(Show)

///|
fn json_string(obj : Map[String, Json], key : String) -> String? {
  match obj.get(key) {
    Some(String(s)) => Some(s)
    _ => None
  }
}

///|
fn json_string_array(obj : Map[String, Json], key : String) -> Array[String] {
  match obj.get(key) {
    Some(Array(arr)) => {
      let out = []
      for v in arr {
        if v is String(s) {
          out.push(s)
        }
      }
      out
    }
    _ => []
  }
}

///|
fn json_number_array(obj : Map[String, Json], key : String) -> Array[Double] {
  match obj.get(key) {
    Some(Array(arr)) => {
      let out = []
      for v in arr {
        if v is Number(n, ..) {
          out.push(n)
        }
      }
      out
    }
    _ => []
  }
}

///|
pub fn PartialSection::from_json(json : Json) -> PartialSection {
  match json {
    Object(obj) =>
      {
        kind: json_string(obj, "kind"),
        title: json_string(obj, "title"),
        text: json_string(obj, "text"),
        value: json_string(obj, "value"),
        unit: json_string(obj, "unit"),
        items: json_string_array(obj, "items"),
        labels: json_string_array(obj, "labels"),
        values: json_number_array(obj, "values"),
      }
    _ =>
      {
        kind: None,
        title: None,
        text: None,
        value: None,
        unit: None,
        items: [],
        labels: [],
        values: [],
      }
  }
}

///|
pub fn PartialDashboard::from_json(json : Json) -> PartialDashboard {
  match json {
    Object(obj) => {
      let sections = match obj.get("sections") {
        Some(Array(arr)) => arr.map(PartialSection::from_json)
        _ => []
      }
      { title: json_string(obj, "title"), sections }
    }
    _ => { title: None, sections: [] }
  }
}
