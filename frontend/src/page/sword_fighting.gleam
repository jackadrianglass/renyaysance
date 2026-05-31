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
  Model(bouts: List(Outcome), saved: Bool)
}

pub fn init() -> Model {
  Model(bouts: [], saved: False)
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  AddBout
  SetOutcome(Int, Outcome)
  RemoveBout(Int)
  Submit
  Saved(Bool)
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    AddBout -> #(
      Model(bouts: list.append(model.bouts, [Pending]), saved: False),
      effect.none(),
    )
    SetOutcome(index, outcome) -> #(
      Model(bouts: set_at(model.bouts, index, outcome), saved: model.saved),
      effect.none(),
    )
    RemoveBout(index) -> #(
      Model(bouts: remove_at(model.bouts, index), saved: False),
      effect.none(),
    )
    Submit -> #(model, do_submit(handle, model.bouts))
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

fn do_submit(handle: String, bouts: List(Outcome)) -> Effect(Msg) {
  let body =
    json.object([
      #("handle", json.string(handle)),
      #(
        "raw",
        json.object([
          #("type", json.string("sword_fighting")),
          #("bouts", json.array(bouts, encode_outcome)),
        ]),
      ),
    ])
  rsvp.post(
    "/api/events/sword-fighting/result",
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
  layout.page("Sword Fighting", [
    html.p([], [html.text("Test your mettle in honorable combat.")]),
    html.div(
      [attribute.class("attempts")],
      list.index_map(model.bouts, view_row),
    ),
    html.button([attribute.class("attempt-add"), event.on_click(AddBout)], [
      html.text("+"),
    ]),
    html.p([], [
      html.text(
        "Wins: "
        <> int.to_string(count_wins(model.bouts))
        <> " / "
        <> int.to_string(list.length(model.bouts)),
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
      html.text("Bout " <> int.to_string(index + 1)),
    ]),
    html.div([attribute.class("attempt-zones")], [
      view_outcome_btn(index, outcome, Won, "Win"),
      view_outcome_btn(index, outcome, Lost, "Loss"),
    ]),
    html.button(
      [attribute.class("attempt-remove"), event.on_click(RemoveBout(index))],
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

fn count_wins(bouts: List(Outcome)) -> Int {
  list.fold(bouts, 0, fn(acc, outcome) {
    acc + case outcome {
      Won -> 1
      Pending | Lost -> 0
    }
  })
}
