import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/string
import gleam/option.{type Option}
import layout
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp

// todo: add a search feature for voting
// todo: percentage of who's got the most points

// MODEL -----------------------------------------------------------------------

pub type Model {
  Model(candidates: List(String), selected: Option(String))
}

pub fn init() -> #(Model, Effect(Msg)) {
  #(Model(candidates: [], selected: option.None), fetch_users())
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  UsersFetched(Result(List(String), rsvp.Error(String)))
  UserVoted(String)
  VoteSubmitted(Bool)
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    UsersFetched(Ok(users)) -> {
      let candidates =
        users
        |> list.filter(fn(u) { u != handle })
        |> list.sort(string.compare)
      #(Model(..model, candidates:), effect.none())
    }
    UsersFetched(Error(_)) -> #(model, effect.none())
    UserVoted(votee) -> #(
      Model(..model, selected: option.Some(votee)),
      do_vote(handle, votee),
    )
    VoteSubmitted(_) -> #(model, effect.none())
  }
}

fn fetch_users() -> Effect(Msg) {
  rsvp.get(
    "/api/users",
    rsvp.expect_json(decode.list(decode.string), UsersFetched),
  )
}

fn do_vote(voter: String, votee: String) -> Effect(Msg) {
  let body =
    json.object([
      #("voter", json.string(voter)),
      #("votee", json.string(votee)),
    ])
  rsvp.post(
    "/api/vote",
    body,
    rsvp.expect_ok_response(fn(result) {
      VoteSubmitted(case result {
        Ok(_) -> True
        Error(_) -> False
      })
    }),
  )
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model) -> Element(Msg) {
  layout.page("Costume Voting", [
    html.p([], [html.text("Vote for the best costume of the day.")]),
    case model.candidates {
      [] -> html.p([], [html.text("No other players yet.")])
      _ ->
        html.div(
          [attribute.class("hunt-items")],
          list.map(model.candidates, fn(candidate) {
            let selected = model.selected == option.Some(candidate)
            view_candidate(candidate, selected)
          }),
        )
    },
    case model.selected {
      option.Some(name) ->
        html.p([attribute.class("saved-message")], [
          html.text("Voted for: " <> name),
        ])
      option.None -> html.p([], [html.text("You haven't voted yet.")])
    },
  ])
}

fn view_candidate(candidate: String, selected: Bool) -> Element(Msg) {
  let row_cls = case selected {
    True -> "hunt-item hunt-item--checked"
    False -> "hunt-item"
  }
  html.div([attribute.class(row_cls)], [
    html.label([attribute.class("hunt-checkbox")], [
      html.input([
        attribute.type_("checkbox"),
        attribute.checked(selected),
        event.on_click(UserVoted(candidate)),
      ]),
      html.span([attribute.class("hunt-checkbox-visual")], []),
    ]),
    html.span([attribute.class("hunt-item-text")], [html.text(candidate)]),
  ])
}
