import envoy
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/int
import gleam/json
import gleam/list
import gleam/option
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

// Change this to the host's handle (the account that can generate the bracket).
const host_handle = "Jack"

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
    Get, ["api", "users"] -> handle_get_users(s)
    Get, ["api", "events"] -> handle_get_events()
    Post, ["api", "events", "potion", "check"] ->
      handle_check_potion(s, req)
    Post, ["api", "events", event_id, "result"] ->
      handle_submit_result(s, event_id, req)
    Get, ["api", "jousting", "state"] -> handle_get_jousting_state(s)
    Post, ["api", "jousting", "signup"] -> handle_jousting_signup(s, req)
    Post, ["api", "jousting", "generate"] -> handle_jousting_generate(s, req)
    Post, ["api", "jousting", "match-result"] ->
      handle_jousting_match_result(s, req)
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
            "https://fonts.googleapis.com/css2?family=MedievalSharp&display=swap",
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

fn handle_get_users(s: store.Store) -> Response {
  store.all_users(s)
  |> json.array(json.string)
  |> json.to_string
  |> wisp.json_response(200)
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

fn handle_check_potion(s: store.Store, req: Request) -> Response {
  use json_body <- wisp.require_json(req)
  case decode.run(json_body, potion_check_decoder()) {
    Error(_) -> wisp.bad_request("Invalid request body")
    Ok(PotionCheckRequest(handle:, answers:)) -> {
      let results = scoring.check_potion_answers(answers)
      let guesses =
        list.filter_map(results, fn(r) {
          case r {
            option.Some(guess) -> Ok(guess)
            option.None -> Error(Nil)
          }
        })
      let raw = scoring.PotionRaw(guesses)
      let points = scoring.score(raw)
      store.upsert_result(s, store.EventResult(handle:, event_id: "potion", raw:, points:))
      json.object([
        #(
          "results",
          json.array(results, fn(r) {
            case r {
              option.Some(scoring.Correct) -> json.string("correct")
              option.Some(scoring.Incorrect) -> json.string("incorrect")
              option.None -> json.string("skipped")
            }
          }),
        ),
      ])
      |> json.to_string
      |> wisp.json_response(200)
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

fn handle_get_jousting_state(s: store.Store) -> Response {
  store.encode_bracket_state_to_string(store.get_bracket_state(s))
  |> wisp.json_response(200)
}

fn handle_jousting_signup(s: store.Store, req: Request) -> Response {
  use json_body <- wisp.require_json(req)
  case decode.run(json_body, handle_decoder()) {
    Error(_) -> wisp.bad_request("Invalid request body")
    Ok(handle) -> {
      store.jousting_signup(s, handle)
      store.encode_bracket_state_to_string(store.get_bracket_state(s))
      |> wisp.json_response(200)
    }
  }
}

fn handle_jousting_generate(s: store.Store, req: Request) -> Response {
  use json_body <- wisp.require_json(req)
  case decode.run(json_body, handle_decoder()) {
    Error(_) -> wisp.bad_request("Invalid request body")
    Ok(handle) ->
      case handle == host_handle {
        False -> wisp.response(403)
        True ->
          store.encode_bracket_state_to_string(store.jousting_generate(s))
          |> wisp.json_response(200)
      }
  }
}

fn handle_jousting_match_result(s: store.Store, req: Request) -> Response {
  use json_body <- wisp.require_json(req)
  case decode.run(json_body, match_result_decoder()) {
    Error(_) -> wisp.bad_request("Invalid request body")
    Ok(#(handle, won)) -> {
      let new_state = store.jousting_record_result(s, handle, won)
      case won {
        True -> {
          let wins = count_bracket_wins(new_state, handle)
          store.upsert_result(
            s,
            store.EventResult(
              handle:,
              event_id: "jousting",
              raw: scoring.JoustingRaw(list.repeat(scoring.Win, wins)),
              points: scoring.score(
                scoring.JoustingRaw(list.repeat(scoring.Win, wins)),
              ),
            ),
          )
        }
        False -> Nil
      }
      store.encode_bracket_state_to_string(new_state)
      |> wisp.json_response(200)
    }
  }
}

fn count_bracket_wins(state: store.BracketState, handle: String) -> Int {
  case state {
    store.SignupPhase(_) -> 0
    store.ActivePhase(rounds) ->
      list.fold(rounds, 0, fn(acc, round) {
        list.fold(round, acc, fn(inner, m) {
          case m.winner == option.Some(handle) {
            True -> inner + 1
            False -> inner
          }
        })
      })
  }
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

type PotionCheckRequest {
  PotionCheckRequest(handle: String, answers: List(String))
}

fn potion_check_decoder() -> decode.Decoder(PotionCheckRequest) {
  use handle <- decode.field("handle", decode.string)
  use answers <- decode.field("answers", decode.list(decode.string))
  decode.success(PotionCheckRequest(handle:, answers:))
}

fn handle_decoder() -> decode.Decoder(String) {
  use handle <- decode.field("handle", decode.string)
  decode.success(handle)
}

fn match_result_decoder() -> decode.Decoder(#(String, Bool)) {
  use handle <- decode.field("handle", decode.string)
  use won <- decode.field("won", decode.bool)
  decode.success(#(handle, won))
}

type VoteRequest {
  VoteRequest(voter: String, votee: String)
}

fn vote_request_decoder() -> decode.Decoder(VoteRequest) {
  use voter <- decode.field("voter", decode.string)
  use votee <- decode.field("votee", decode.string)
  decode.success(VoteRequest(voter:, votee:))
}
