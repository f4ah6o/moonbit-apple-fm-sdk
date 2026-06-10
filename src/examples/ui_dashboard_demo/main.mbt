///|
/// On-device generative UI demo: natural-language request in, a dashboard UI
/// tree streamed out as schema-constrained snapshots over SSE, rendered live
/// in the browser. Run with:
///   moon run src/examples/ui_dashboard_demo --target native
/// then open http://127.0.0.1:8080

///|
let listen_addr : String = "127.0.0.1:8080"

///|
/// The C bridge has a single global response pipe, so generations must not
/// overlap; concurrent /generate requests get 429.
let busy : Ref[Bool] = Ref(false)

///|
fn release_busy() -> Unit {
  busy.val = false
}

///|
fn hex_val(c : Char) -> Int {
  if c >= '0' && c <= '9' {
    c.to_int() - '0'.to_int()
  } else if c >= 'a' && c <= 'f' {
    c.to_int() - 'a'.to_int() + 10
  } else if c >= 'A' && c <= 'F' {
    c.to_int() - 'A'.to_int() + 10
  } else {
    -1
  }
}

///|
/// Decode %XX escapes and '+' in a URL query value, then interpret the byte
/// sequence as UTF-8 (required for Japanese prompts).
fn percent_decode(s : String) -> String {
  let bytes : Array[Byte] = []
  let chars = s.to_array()
  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    if c == '%' && i + 2 < chars.length() {
      let hi = hex_val(chars[i + 1])
      let lo = hex_val(chars[i + 2])
      if hi >= 0 && lo >= 0 {
        bytes.push(((hi << 4) | lo).to_byte())
        i += 3
        continue
      }
    }
    if c == '+' {
      bytes.push(b' ')
      i += 1
      continue
    }
    let code = c.to_int()
    if code < 0x80 {
      bytes.push(code.to_byte())
    }
    i += 1
  }
  @utf8.decode_lossy(Bytes::from_array(bytes))
}

///|
fn query_param(path : String, key : String) -> String? {
  let parts = path.split("?").collect()
  if parts.length() < 2 {
    return None
  }
  for pair in parts[1].split("&") {
    let kv = pair.split("=").collect()
    if kv.length() == 2 && kv[0].to_owned() == key {
      return Some(percent_decode(kv[1].to_owned()))
    }
  }
  None
}

///|
fn sanitize_for_sse(s : String) -> String {
  s.replace_all(old="\r", new=" ").replace_all(old="\n", new=" ")
}

///|
async fn serve_generate(conn : @http.ServerConnection, path : String) -> Unit {
  guard query_param(path, "q") is Some(prompt) && !prompt.is_empty() else {
    conn..send_response(400, "Bad Request").write_string("missing q parameter")
    return
  }
  if busy.val {
    conn
    ..send_response(429, "Too Many Requests")
    .write_string("a generation is already running")
    return
  }
  busy.val = true
  defer release_busy()
  conn.send_response(200, "OK", extra_headers={
    "Content-Type": "text/event-stream; charset=utf-8",
    "Cache-Control": "no-cache",
  })
  let session = @session.LanguageModelSession::new(
    instructions=Some(
      "You generate dashboard UI definitions answering the user's request. " +
      "Use concrete, plausible sample data. Mix section kinds. " +
      "Respond in the same language as the user's request.",
    ),
  )
  let schema = @ui_ast.dashboard_schema()
  let stream = session.start_structured_stream(prompt, schema)
  // NOTE: @ffi.read_response blocks the whole event loop between snapshots.
  // Acceptable for this single-user PoC since generations are serialized;
  // the upgrade path is exposing the pipe read fd from ffi_stub.c and
  // reading it with moonbitlang/async's raw_fd support.
  while true {
    let (status, content) = @ffi.read_response(262144)
    if status != 0 {
      conn.write_string("event: error\ndata: \{sanitize_for_sse(content)}\n\n")
      break
    }
    if content.is_empty() {
      conn.write_string("event: done\ndata: {}\n\n")
      break
    }
    // Snapshots are compact single-line JSON; split defensively anyway,
    // since a data: frame must not contain raw newlines.
    for line in content.split("\n") {
      conn.write_string("data: \{line.to_owned()}\n")
    }
    conn.write_string("\n")
    conn.flush()
  }
  @ffi.release_stream(stream)
  schema.release()
  session.release()
  conn.end_response()
}

///|
async fn main {
  let model = @core.SystemLanguageModel::new()
  let (available, reason) = model.is_available()
  if !available {
    println("Apple Intelligence model not available on this machine")
    ignore(reason)
    return
  }
  println("Serving on http://\{listen_addr}")
  @http.Server(@socket.Addr::parse(listen_addr)).run_forever((
    request,
    _body,
    conn,
  ) => {
    match (request.meth, request.path) {
      (Get, "/") =>
        conn
        ..send_response(200, "OK", extra_headers={
          "Content-Type": "text/html; charset=utf-8",
        })
        .write_string(page_html)
      (Get, path) => {
        if path.has_prefix("/generate?") || path == "/generate" {
          serve_generate(conn, path)
        } else {
          conn.send_response(404, "Not Found")
        }
      }
      _ => conn.send_response(404, "Not Found")
    }
  })
}
