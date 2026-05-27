import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/json
import gleam/list
import gleam/result
import lustre/attribute
import lustre/element
import lustre/element/html
import mist
import storail
import wisp.{type Request, type Response}
import wisp/wisp_mist

// Change this to your party password before deploying.
const party_password = "renaissance"

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let assert Ok(users_db) = setup_users_db()

  let assert Ok(priv_directory) = wisp.priv_directory("backend")
  let static_directory = priv_directory <> "/static"

  let assert Ok(_) =
    handle_request(users_db, static_directory, _)
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(3000)
    |> mist.start

  process.sleep_forever()
}

// MIDDLEWARE ------------------------------------------------------------------

fn app_middleware(
  req: Request,
  static_directory: String,
  next: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/static", from: static_directory)

  next(req)
}

// REQUEST HANDLERS ------------------------------------------------------------

fn handle_request(
  users_db: storail.Collection(List(String)),
  static_directory: String,
  req: Request,
) -> Response {
  use req <- app_middleware(req, static_directory)

  case req.method, wisp.path_segments(req) {
    Post, ["api", "login"] -> handle_login(users_db, req)
    Get, _ -> serve_index()
    _, _ -> wisp.not_found()
  }
}

fn serve_index() -> Response {
  let html =
    html.html([], [
      html.head([], [
        html.meta([attribute.attribute("charset", "utf-8")]),
        html.meta([
          attribute.attribute("name", "viewport"),
          attribute.attribute("content", "width=device-width, initial-scale=1"),
        ]),
        html.title([], "Rennyaysance"),
        html.script(
          [attribute.type_("module"), attribute.src("/static/frontend.js")],
          "",
        ),
      ]),
      html.body([], [html.div([attribute.id("app")], [])]),
    ])

  html
  |> element.to_document_string
  |> wisp.html_response(200)
}

type LoginRequest {
  LoginRequest(name: String, password: String)
}

fn login_request_decoder() -> decode.Decoder(LoginRequest) {
  use name <- decode.field("name", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(LoginRequest(name:, password:))
}

fn handle_login(db: storail.Collection(List(String)), req: Request) -> Response {
  use json_body <- wisp.require_json(req)
  case decode.run(json_body, login_request_decoder()) {
    Error(_) -> wisp.bad_request("Invalid request body")
    Ok(LoginRequest(name:, password:)) ->
      case password == party_password {
        False -> wisp.response(401)
        True -> {
          upsert_user(db, name)
          json.to_string(json.object([#("name", json.string(name))]))
          |> wisp.json_response(200)
        }
      }
  }
}

// DATABASE --------------------------------------------------------------------

fn setup_users_db() -> Result(storail.Collection(List(String)), Nil) {
  let config = storail.Config(storage_path: "./data")
  let users =
    storail.Collection(
      name: "users",
      to_json: fn(names) { json.array(names, json.string) },
      decoder: decode.list(decode.string),
      config:,
    )
  Ok(users)
}

fn users_key(
  db: storail.Collection(List(String)),
) -> storail.Key(List(String)) {
  storail.key(db, "all")
}

fn upsert_user(db: storail.Collection(List(String)), name: String) -> Nil {
  let users = storail.read(users_key(db)) |> result.unwrap([])
  case list.contains(users, name) {
    True -> Nil
    False -> {
      let _ = storail.write(users_key(db), list.append(users, [name]))
      Nil
    }
  }
}
