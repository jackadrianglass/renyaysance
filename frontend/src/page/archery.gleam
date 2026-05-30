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
  Model(shots: [], saved: False)
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  AddShot(Zone)
  RemoveLast
  Submit
  Saved(Bool)
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    AddShot(zone) -> #(
      Model(shots: list.append(model.shots, [zone]), saved: False),
      effect.none(),
    )
    RemoveLast -> #(
      Model(shots: drop_last(model.shots), saved: False),
      effect.none(),
    )
    Submit -> #(model, do_submit(handle, model.shots))
    Saved(ok) -> #(Model(..model, saved: ok), effect.none())
  }
}

fn drop_last(lst: List(a)) -> List(a) {
  lst |> list.reverse |> list.drop(1) |> list.reverse
}

fn do_submit(handle: String, shots: List(Zone)) -> Effect(Msg) {
  let body =
    json.object([
      #("handle", json.string(handle)),
      #(
        "raw",
        json.object([
          #("type", json.string("archery")),
          #("shots", json.array(shots, encode_zone)),
        ]),
      ),
    ])
  rsvp.post(
    "/api/events/archery/result",
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
  layout.page("Archery", [
    html.p([], [html.text("Loose your arrows and claim your score.")]),
    view_shots(model.shots),
    html.p([], [
      html.text("Score: " <> int.to_string(compute_score(model.shots)) <> " pts"),
    ]),
    html.div([attribute.class("attempt-buttons")], [
      html.button([event.on_click(AddShot(Missed))], [html.text("Missed")]),
      html.button([event.on_click(AddShot(OuterRing))], [
        html.text("Outer Ring"),
      ]),
      html.button([event.on_click(AddShot(InnerRing))], [
        html.text("Inner Ring"),
      ]),
      html.button([event.on_click(AddShot(Bullseye))], [html.text("Bullseye")]),
      html.button([event.on_click(RemoveLast)], [html.text("Undo")]),
    ]),
    case model.saved {
      True ->
        html.p([attribute.class("saved-message")], [html.text("Score saved!")])
      False ->
        html.button([event.on_click(Submit)], [html.text("Save Score")])
    },
  ])
}

fn view_shots(shots: List(Zone)) -> Element(msg) {
  case shots {
    [] -> html.p([], [html.text("No shots yet.")])
    _ ->
      html.div(
        [attribute.class("attempts")],
        list.map(shots, fn(zone) {
          let #(label, cls) = case zone {
            Missed -> #("M", "attempt attempt--missed")
            OuterRing -> #("O", "attempt attempt--outer")
            InnerRing -> #("I", "attempt attempt--inner")
            Bullseye -> #("B", "attempt attempt--bullseye")
          }
          html.span([attribute.class(cls)], [html.text(label)])
        }),
      )
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
