import envoy
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/int
import gleam/json
import gleam/list
import lustre/attribute
import lustre/element
import lustre/element/html
import mist
import scoring
import store
import wisp.{type Request, type Response}
import wisp/wisp_mist

// Change this to your party password before deploying.
const party_password = "renaissance"

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let s = store.setup()

  let assert Ok(priv_directory) = wisp.priv_directory("backend")
  let static_directory = priv_directory <> "/static"

  let host = get_host()
  let port = get_port()

  let assert Ok(_) =
    handle_request(s, static_directory, _)
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.bind(host)
    |> mist.port(port)
    |> mist.start

  process.sleep_forever()
}

fn get_host() -> String {
  case envoy.get("HOST") {
    Ok(host) -> host
    Error(_) -> "localhost"
  }
}

fn get_port() -> Int {
  case envoy.get("PORT") {
    Ok(port) ->
      case int.parse(port) {
        Ok(n) -> n
        Error(_) -> 3000
      }
    Error(_) -> 3000
  }
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
  s: store.Store,
  static_directory: String,
  req: Request,
) -> Response {
  use req <- app_middleware(req, static_directory)

  case req.method, wisp.path_segments(req) {
    Post, ["api", "login"] -> handle_login(s, req)
    Get, ["api", "events"] -> handle_get_events()
    Post, ["api", "events", event_id, "result"] ->
      handle_submit_result(s, event_id, req)
    Post, ["api", "vote"] -> handle_vote(s, req)
    Get, ["api", "leaderboard"] -> handle_get_leaderboard(s)
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
        html.link([
          attribute.attribute("rel", "preconnect"),
          attribute.href("https://fonts.googleapis.com"),
        ]),
        html.link([
          attribute.attribute("rel", "preconnect"),
          attribute.href("https://fonts.gstatic.com"),
          attribute.attribute("crossorigin", ""),
        ]),
        html.link([
          attribute.attribute("rel", "stylesheet"),
          attribute.href(
            "https://fonts.googleapis.com/css2?family=Jacquard+24&display=swap",
          ),
        ]),
        html.link([
          attribute.attribute("rel", "stylesheet"),
          attribute.href("https://unpkg.com/open-props/open-props.min.css"),
        ]),
        html.link([
          attribute.attribute("rel", "stylesheet"),
          attribute.href("/static/app.css"),
        ]),
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

fn handle_login(s: store.Store, req: Request) -> Response {
  use json_body <- wisp.require_json(req)
  case decode.run(json_body, login_request_decoder()) {
    Error(_) -> wisp.bad_request("Invalid request body")
    Ok(LoginRequest(name:, password:)) ->
      case password == party_password {
        False -> wisp.response(401)
        True -> {
          store.upsert_user(s, name)
          json.to_string(json.object([#("name", json.string(name))]))
          |> wisp.json_response(200)
        }
      }
  }
}

fn handle_get_events() -> Response {
  json.array(scoring.events(), fn(event) {
    json.object([
      #("id", json.string(event.id)),
      #("label", json.string(event.label)),
    ])
  })
  |> json.to_string
  |> wisp.json_response(200)
}

fn handle_submit_result(
  s: store.Store,
  event_id: String,
  req: Request,
) -> Response {
  let self_report_ids =
    scoring.events()
    |> list.filter(fn(e) { e.id != "voting" })
    |> list.map(fn(e) { e.id })

  case list.contains(self_report_ids, event_id) {
    False -> wisp.not_found()
    True -> {
      use json_body <- wisp.require_json(req)
      case decode.run(json_body, submit_result_decoder()) {
        Error(_) -> wisp.bad_request("Invalid request body")
        Ok(SubmitResultRequest(handle:, raw:)) -> {
          let points = scoring.score(raw)
          store.upsert_result(
            s,
            store.EventResult(handle:, event_id:, raw:, points:),
          )
          wisp.response(204)
        }
      }
    }
  }
}

fn handle_vote(s: store.Store, req: Request) -> Response {
  use json_body <- wisp.require_json(req)
  case decode.run(json_body, vote_request_decoder()) {
    Error(_) -> wisp.bad_request("Invalid request body")
    Ok(VoteRequest(voter:, votee:)) -> {
      store.upsert_vote(s, store.Vote(voter:, votee:))
      store.recompute_voting_results(s, store.all_users(s))
      wisp.response(204)
    }
  }
}

fn handle_get_leaderboard(s: store.Store) -> Response {
  store.leaderboard(s)
  |> json.array(fn(entry) {
    json.object([
      #("handle", json.string(entry.0)),
      #("points", json.int(entry.1)),
    ])
  })
  |> json.to_string
  |> wisp.json_response(200)
}

// REQUEST DECODERS ------------------------------------------------------------

type LoginRequest {
  LoginRequest(name: String, password: String)
}

fn login_request_decoder() -> decode.Decoder(LoginRequest) {
  use name <- decode.field("name", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(LoginRequest(name:, password:))
}

type SubmitResultRequest {
  SubmitResultRequest(handle: String, raw: scoring.RawInput)
}

fn submit_result_decoder() -> decode.Decoder(SubmitResultRequest) {
  use handle <- decode.field("handle", decode.string)
  use raw <- decode.field("raw", scoring.raw_input_decoder())
  decode.success(SubmitResultRequest(handle:, raw:))
}

type VoteRequest {
  VoteRequest(voter: String, votee: String)
}

fn vote_request_decoder() -> decode.Decoder(VoteRequest) {
  use voter <- decode.field("voter", decode.string)
  use votee <- decode.field("votee", decode.string)
  decode.success(VoteRequest(voter:, votee:))
}
