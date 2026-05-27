import gleam/bytes_tree
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string
import mist.{type Connection, type ResponseData}

const static_dir = "priv/static"

pub fn main() {
  let assert Ok(_) =
    mist.new(handle_request)
    |> mist.port(8080)
    |> mist.start

  process.sleep_forever()
}

fn handle_request(req: request.Request(Connection)) -> response.Response(ResponseData) {
  case request.path_segments(req) {
    [] -> serve_file(static_dir <> "/index.html", "text/html; charset=utf-8")
    [file] -> serve_file(static_dir <> "/" <> file, content_type(file))
    _ -> not_found()
  }
}

fn content_type(filename: String) -> String {
  let ext =
    string.split(filename, ".")
    |> list.last
    |> result.unwrap("")
  case ext {
    "js" -> "application/javascript"
    "css" -> "text/css"
    "html" -> "text/html; charset=utf-8"
    _ -> "application/octet-stream"
  }
}

fn serve_file(path: String, ct: String) -> response.Response(ResponseData) {
  case mist.send_file(path, offset: 0, limit: None) {
    Ok(file) ->
      response.new(200)
      |> response.set_header("content-type", ct)
      |> response.set_body(file)
    Error(_) -> not_found()
  }
}

fn not_found() -> response.Response(ResponseData) {
  response.new(404)
  |> response.set_body(mist.Bytes(bytes_tree.from_string("Not found")))
}
