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
  Saved(Bool)
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    AddShot -> {
      let new_shots = list.append(model.shots, [Missed])
      #(Model(shots: new_shots, saved: False), do_submit(handle, new_shots))
    }
    SetShot(index, zone) -> {
      let new_shots = set_at(model.shots, index, zone)
      #(Model(shots: new_shots, saved: False), do_submit(handle, new_shots))
    }
    RemoveShot(index) -> {
      let new_shots = remove_at(model.shots, index)
      #(Model(shots: new_shots, saved: False), do_submit(handle, new_shots))
    }
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
      False -> html.text("")
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
    html.select(
      [
        attribute.class("attempt-select"),
        event.on_input(fn(val) { SetShot(index, zone_from_string(val)) }),
      ],
      [
        view_option(zone, Missed, "Missed"),
        view_option(zone, OuterRing, "Outer Ring"),
        view_option(zone, InnerRing, "Inner Ring"),
        view_option(zone, Bullseye, "Bullseye"),
      ],
    ),
    html.button(
      [attribute.class("attempt-remove"), event.on_click(RemoveShot(index))],
      [html.text("✕")],
    ),
  ])
}

fn view_option(current: Zone, zone: Zone, label: String) -> Element(Msg) {
  html.option(
    [attribute.value(zone_to_string(zone)), attribute.selected(current == zone)],
    label,
  )
}

fn zone_to_string(zone: Zone) -> String {
  case zone {
    Missed -> "missed"
    OuterRing -> "outer_ring"
    InnerRing -> "inner_ring"
    Bullseye -> "bullseye"
  }
}

fn zone_from_string(s: String) -> Zone {
  case s {
    "outer_ring" -> OuterRing
    "inner_ring" -> InnerRing
    "bullseye" -> Bullseye
    _ -> Missed
  }
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
