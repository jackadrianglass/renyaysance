import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import layout
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp

// MODEL -----------------------------------------------------------------------

pub type BracketMatch {
  BracketMatch(p1: Option(String), p2: Option(String), winner: Option(String))
}

pub type BracketPhase {
  Loading
  SignupPhase(participants: List(String))
  ActivePhase(rounds: List(List(BracketMatch)))
}

pub type Model {
  Model(phase: BracketPhase, result_sent: Bool)
}

const host_handle = "Jack"

pub fn init() -> #(Model, Effect(Msg)) {
  #(Model(phase: Loading, result_sent: False), fetch_state())
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  StateFetched(Result(BracketPhase, rsvp.Error(String)))
  SignUp
  GenerateBracket
  RecordResult(Bool)
  ActionDone(Result(BracketPhase, rsvp.Error(String)))
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    StateFetched(Ok(phase)) -> #(Model(..model, phase:), effect.none())
    StateFetched(Error(_)) -> #(model, effect.none())

    SignUp -> #(model, do_signup(handle))
    GenerateBracket -> #(model, do_generate(handle))
    RecordResult(won) -> #(
      Model(..model, result_sent: True),
      do_match_result(handle, won),
    )

    ActionDone(Ok(phase)) -> #(Model(phase:, result_sent: False), effect.none())
    ActionDone(Error(_)) -> #(Model(..model, result_sent: False), effect.none())
  }
}

pub fn fetch_state() -> Effect(Msg) {
  rsvp.get("/api/jousting/state", rsvp.expect_json(phase_decoder(), StateFetched))
}

fn do_signup(handle: String) -> Effect(Msg) {
  let body = json.object([#("handle", json.string(handle))])
  rsvp.post(
    "/api/jousting/signup",
    body,
    rsvp.expect_json(phase_decoder(), ActionDone),
  )
}

fn do_generate(handle: String) -> Effect(Msg) {
  let body = json.object([#("handle", json.string(handle))])
  rsvp.post(
    "/api/jousting/generate",
    body,
    rsvp.expect_json(phase_decoder(), ActionDone),
  )
}

fn do_match_result(handle: String, won: Bool) -> Effect(Msg) {
  let body =
    json.object([
      #("handle", json.string(handle)),
      #("won", json.bool(won)),
    ])
  rsvp.post(
    "/api/jousting/match-result",
    body,
    rsvp.expect_json(phase_decoder(), ActionDone),
  )
}

// DECODER ---------------------------------------------------------------------

fn phase_decoder() -> decode.Decoder(BracketPhase) {
  use phase_tag <- decode.field("phase", decode.string)
  case phase_tag {
    "active" -> {
      use rounds <- decode.field(
        "rounds",
        decode.list(decode.list(bracket_match_decoder())),
      )
      decode.success(ActivePhase(rounds))
    }
    _ -> {
      use participants <- decode.field("participants", decode.list(decode.string))
      decode.success(SignupPhase(participants))
    }
  }
}

fn bracket_match_decoder() -> decode.Decoder(BracketMatch) {
  use p1 <- decode.field("p1", decode.optional(decode.string))
  use p2 <- decode.field("p2", decode.optional(decode.string))
  use winner <- decode.field("winner", decode.optional(decode.string))
  decode.success(BracketMatch(p1:, p2:, winner:))
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model, handle: String) -> Element(Msg) {
  let is_host = handle == host_handle
  layout.page("King's Court Jousting", [
    case model.phase {
      Loading -> html.p([], [html.text("Loading bracket…")])
      SignupPhase(participants) ->
        view_signup(participants, handle, is_host)
      ActivePhase(rounds) ->
        view_bracket(rounds, handle, model.result_sent)
    },
  ])
}

fn view_signup(
  participants: List(String),
  handle: String,
  is_host: Bool,
) -> Element(Msg) {
  let signed_up = list.contains(participants, handle)
  html.div([attribute.class("jousting-signup")], [
    html.p([], [
      html.text(
        "Champions signed up: " <> int.to_string(list.length(participants)),
      ),
    ]),
    html.ul(
      [attribute.class("jousting-signup-list")],
      list.map(participants, fn(p) { html.li([], [html.text(p)]) }),
    ),
    case signed_up {
      True ->
        html.p([attribute.class("saved-message")], [
          html.text("You're signed up!"),
        ])
      False ->
        html.button([event.on_click(SignUp)], [html.text("Sign Up")])
    },
    case is_host {
      True ->
        html.button(
          [
            attribute.class("jousting-generate"),
            event.on_click(GenerateBracket),
          ],
          [html.text("Generate Bracket")],
        )
      False ->
        html.p([attribute.class("jousting-waiting")], [
          html.text("Waiting for host to start the bracket…"),
        ])
    },
  ])
}

fn view_bracket(
  rounds: List(List(BracketMatch)),
  handle: String,
  result_sent: Bool,
) -> Element(Msg) {
  let active_match = find_active_match(rounds, handle)
  html.div([], [
    view_match_controls(active_match, result_sent),
    html.div(
      [attribute.class("bracket")],
      list.index_map(rounds, fn(round, ri) {
        view_round(round, handle, active_match, ri, list.length(rounds))
      }),
    ),
  ])
}

fn view_match_controls(
  active_match: Option(#(Int, Int)),
  result_sent: Bool,
) -> Element(Msg) {
  case active_match {
    None -> html.p([], [html.text("You have no active match.")])
    Some(_) ->
      case result_sent {
        True ->
          html.p([attribute.class("saved-message")], [
            html.text("Result recorded!"),
          ])
        False ->
          html.div([attribute.class("jousting-controls")], [
            html.p([], [html.text("Record your match result:")]),
            html.button(
              [
                attribute.class("jousting-win-btn"),
                event.on_click(RecordResult(True)),
              ],
              [html.text("I Won")],
            ),
            html.button(
              [
                attribute.class("jousting-loss-btn"),
                event.on_click(RecordResult(False)),
              ],
              [html.text("I Lost")],
            ),
          ])
      }
  }
}

fn view_round(
  round: List(BracketMatch),
  handle: String,
  active_match: Option(#(Int, Int)),
  round_idx: Int,
  total_rounds: Int,
) -> Element(Msg) {
  let label = case round_idx == total_rounds - 1 {
    True -> "Final"
    False ->
      case round_idx == total_rounds - 2 {
        True -> "Semi-finals"
        False -> "Round " <> int.to_string(round_idx + 1)
      }
  }
  html.div([attribute.class("bracket-round")], [
    html.p([attribute.class("bracket-round-label")], [html.text(label)]),
    html.div(
      [attribute.class("bracket-matches")],
      list.index_map(round, fn(m, mi) {
        let is_active = active_match == Some(#(round_idx, mi))
        view_match(m, handle, is_active)
      }),
    ),
  ])
}

fn view_match(
  m: BracketMatch,
  handle: String,
  is_active: Bool,
) -> Element(Msg) {
  let cls = case is_active {
    True -> "bracket-match bracket-match--active"
    False -> "bracket-match"
  }
  html.div([attribute.class(cls)], [
    view_player_slot(m.p1, m.winner, handle),
    html.div([attribute.class("bracket-match-divider")], []),
    view_player_slot(m.p2, m.winner, handle),
  ])
}

fn view_player_slot(
  player: Option(String),
  winner: Option(String),
  handle: String,
) -> Element(Msg) {
  let name = case player {
    None -> "BYE"
    Some(p) -> p
  }
  let is_winner = player != None && player == winner
  let is_me = player == Some(handle)
  let cls =
    "bracket-match-player"
    <> case is_winner {
      True -> " bracket-match-player--winner"
      False -> ""
    }
    <> case is_me {
      True -> " bracket-match-player--me"
      False -> ""
    }
  html.div([attribute.class(cls)], [html.text(name)])
}

fn find_active_match(
  rounds: List(List(BracketMatch)),
  handle: String,
) -> Option(#(Int, Int)) {
  list.index_fold(rounds, None, fn(acc, round, ri) {
    case acc {
      Some(_) -> acc
      None ->
        list.index_fold(round, None, fn(inner, m, mi) {
          case inner {
            Some(_) -> inner
            None ->
              case m.winner {
                Some(_) -> None
                None ->
                  case m.p1 == Some(handle) || m.p2 == Some(handle) {
                    True -> Some(#(ri, mi))
                    False -> None
                  }
              }
          }
        })
    }
  })
}
