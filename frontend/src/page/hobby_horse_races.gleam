import gleam/int
import gleam/json
import gleam/list
import layout
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp

// MODEL -----------------------------------------------------------------------

pub type Outcome {
  Pending
  Won
  Lost
}

pub type Model {
  Model(races: List(Outcome), saved: Bool)
}

pub fn init() -> Model {
  Model(races: [], saved: False)
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  AddRace
  SetOutcome(Int, Outcome)
  RemoveRace(Int)
  Submit
  Saved(Bool)
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    AddRace -> #(
      Model(races: list.append(model.races, [Pending]), saved: False),
      effect.none(),
    )
    SetOutcome(index, outcome) -> #(
      Model(races: set_at(model.races, index, outcome), saved: model.saved),
      effect.none(),
    )
    RemoveRace(index) -> #(
      Model(races: remove_at(model.races, index), saved: False),
      effect.none(),
    )
    Submit -> #(model, do_submit(handle, model.races))
    Saved(ok) -> #(Model(..model, saved: ok), effect.none())
  }
}

fn set_at(lst: List(a), target: Int, value: a) -> List(a) {
  list.index_map(lst, fn(item, i) {
    case i == target {
      True -> value
      False -> item
    }
  })
}

fn remove_at(lst: List(a), index: Int) -> List(a) {
  list.flatten([list.take(lst, index), list.drop(lst, index + 1)])
}

fn do_submit(handle: String, races: List(Outcome)) -> Effect(Msg) {
  let body =
    json.object([
      #("handle", json.string(handle)),
      #(
        "raw",
        json.object([
          #("type", json.string("hobby_horse")),
          #("races", json.array(races, encode_outcome)),
        ]),
      ),
    ])
  rsvp.post(
    "/api/events/hobby-horse/result",
    body,
    rsvp.expect_ok_response(fn(result) { Saved(result_is_ok(result)) }),
  )
}

fn encode_outcome(outcome: Outcome) -> json.Json {
  case outcome {
    Pending -> json.string("pending")
    Won -> json.string("won")
    Lost -> json.string("lost")
  }
}

fn result_is_ok(r: Result(a, b)) -> Bool {
  case r {
    Ok(_) -> True
    Error(_) -> False
  }
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model) -> Element(Msg) {
  layout.page("Hobby Horse Races", [
    html.p([], [html.text("Mount up. The track awaits.")]),
    html.div(
      [attribute.class("attempts")],
      list.index_map(model.races, view_row),
    ),
    html.button([attribute.class("attempt-add"), event.on_click(AddRace)], [
      html.text("+"),
    ]),
    html.p([], [
      html.text(
        "Wins: "
        <> int.to_string(count_wins(model.races))
        <> " / "
        <> int.to_string(list.length(model.races)),
      ),
    ]),
    case model.saved {
      True ->
        html.p([attribute.class("saved-message")], [html.text("Score saved!")])
      False ->
        html.button([event.on_click(Submit)], [html.text("Save Score")])
    },
  ])
}

fn view_row(outcome: Outcome, index: Int) -> Element(Msg) {
  let row_cls = case outcome {
    Pending -> "attempt-row"
    Won -> "attempt-row attempt-row--bullseye"
    Lost -> "attempt-row attempt-row--missed"
  }
  html.div([attribute.class(row_cls)], [
    html.span([attribute.class("attempt-num")], [
      html.text("Race " <> int.to_string(index + 1)),
    ]),
    html.div([attribute.class("attempt-zones")], [
      view_outcome_btn(index, outcome, Won, "Win"),
      view_outcome_btn(index, outcome, Lost, "Loss"),
    ]),
    html.button(
      [attribute.class("attempt-remove"), event.on_click(RemoveRace(index))],
      [html.text("✕")],
    ),
  ])
}

fn view_outcome_btn(
  index: Int,
  current: Outcome,
  outcome: Outcome,
  label: String,
) -> Element(Msg) {
  let cls = case current == outcome {
    True -> "attempt-btn selected"
    False -> "attempt-btn"
  }
  html.button(
    [attribute.class(cls), event.on_click(SetOutcome(index, outcome))],
    [html.text(label)],
  )
}

fn count_wins(races: List(Outcome)) -> Int {
  list.fold(races, 0, fn(acc, outcome) {
    acc + case outcome {
      Won -> 1
      Pending | Lost -> 0
    }
  })
}
