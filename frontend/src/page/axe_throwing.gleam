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

pub type Zone {
  Missed
  OuterRing
  InnerRing
  Bullseye
}

pub type Model {
  Model(shots: List(Zone), saved: Bool)
}

pub fn init() -> Model {
  Model(shots: [Missed], saved: False)
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  AddShot
  SetShot(Int, Zone)
  RemoveShot(Int)
  Submit
  Saved(Bool)
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    AddShot -> #(
      Model(shots: list.append(model.shots, [Missed]), saved: False),
      effect.none(),
    )
    SetShot(index, zone) -> #(
      Model(shots: set_at(model.shots, index, zone), saved: model.saved),
      effect.none(),
    )
    RemoveShot(index) -> #(
      Model(shots: remove_at(model.shots, index), saved: False),
      effect.none(),
    )
    Submit -> #(model, do_submit(handle, model.shots))
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

fn do_submit(handle: String, shots: List(Zone)) -> Effect(Msg) {
  let body =
    json.object([
      #("handle", json.string(handle)),
      #(
        "raw",
        json.object([
          #("type", json.string("axe_throwing")),
          #("shots", json.array(shots, encode_zone)),
        ]),
      ),
    ])
  rsvp.post(
    "/api/events/axe-throwing/result",
    body,
    rsvp.expect_ok_response(fn(result) { Saved(result_is_ok(result)) }),
  )
}

fn encode_zone(zone: Zone) -> json.Json {
  case zone {
    Missed -> json.string("missed")
    OuterRing -> json.string("outer_ring")
    InnerRing -> json.string("inner_ring")
    Bullseye -> json.string("bullseye")
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
  layout.page("Axe Throwing", [
    html.p([], [html.text("Hurl your axe and claim your score.")]),
    html.div(
      [attribute.class("attempts")],
      list.index_map(model.shots, view_row),
    ),
    html.button([attribute.class("attempt-add"), event.on_click(AddShot)], [
      html.text("+"),
    ]),
    html.p([], [
      html.text("Score: " <> int.to_string(compute_score(model.shots)) <> " pts"),
    ]),
    case model.saved {
      True ->
        html.p([attribute.class("saved-message")], [html.text("Score saved!")])
      False ->
        html.button([event.on_click(Submit)], [html.text("Save Score")])
    },
  ])
}

fn view_row(zone: Zone, index: Int) -> Element(Msg) {
  let row_cls = case zone {
    Missed -> "attempt-row attempt-row--missed"
    OuterRing -> "attempt-row attempt-row--outer"
    InnerRing -> "attempt-row attempt-row--inner"
    Bullseye -> "attempt-row attempt-row--bullseye"
  }
  html.div([attribute.class(row_cls)], [
    html.span([attribute.class("attempt-num")], [
      html.text(int.to_string(index + 1)),
    ]),
    html.div([attribute.class("attempt-zones")], [
      view_zone_btn(index, zone, Missed, "Missed"),
      view_zone_btn(index, zone, OuterRing, "Outer Ring"),
      view_zone_btn(index, zone, InnerRing, "Inner Ring"),
      view_zone_btn(index, zone, Bullseye, "Bullseye"),
    ]),
    html.button(
      [attribute.class("attempt-remove"), event.on_click(RemoveShot(index))],
      [html.text("✕")],
    ),
  ])
}

fn view_zone_btn(
  index: Int,
  current: Zone,
  zone: Zone,
  label: String,
) -> Element(Msg) {
  let cls = case current == zone {
    True -> "attempt-btn selected"
    False -> "attempt-btn"
  }
  html.button(
    [attribute.class(cls), event.on_click(SetShot(index, zone))],
    [html.text(label)],
  )
}

fn compute_score(shots: List(Zone)) -> Int {
  list.fold(shots, 0, fn(acc, zone) {
    acc + case zone {
      Missed -> 0
      OuterRing -> 3
      InnerRing -> 7
      Bullseye -> 10
    }
  })
}
