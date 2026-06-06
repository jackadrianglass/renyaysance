import gleam/int
import gleam/json
import gleam/list
import gleam/result
import layout
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp

// MODEL -----------------------------------------------------------------------

pub type Model {
  Model(shots: List(List(Bool)), saved: Bool)
}

fn empty_shot() -> List(Bool) {
  list.repeat(False, 10)
}

pub fn init() -> Model {
  Model(shots: [empty_shot()], saved: False)
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  AddShot
  ToggleCup(Int, Int)
  RemoveShot(Int)
  Saved(Bool)
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    AddShot -> {
      let new_shots = list.append(model.shots, [empty_shot()])
      #(Model(shots: new_shots, saved: False), do_submit(handle, new_shots))
    }
    ToggleCup(shot_idx, cup_idx) -> {
      let new_shots =
        list.index_map(model.shots, fn(shot, i) {
          case i == shot_idx {
            False -> shot
            True ->
              list.index_map(shot, fn(knocked, j) {
                case j == cup_idx {
                  True -> !knocked
                  False -> knocked
                }
              })
          }
        })
      #(Model(shots: new_shots, saved: False), do_submit(handle, new_shots))
    }
    RemoveShot(index) -> {
      let new_shots =
        list.flatten([
          list.take(model.shots, index),
          list.drop(model.shots, index + 1),
        ])
      #(Model(shots: new_shots, saved: False), do_submit(handle, new_shots))
    }
    Saved(ok) -> #(Model(..model, saved: ok), effect.none())
  }
}

fn do_submit(handle: String, shots: List(List(Bool))) -> Effect(Msg) {
  let body =
    json.object([
      #("handle", json.string(handle)),
      #(
        "raw",
        json.object([
          #("type", json.string("archery")),
          #(
            "shots",
            json.array(shots, fn(shot) {
              shot
              |> list.index_map(fn(knocked, i) { #(knocked, i + 1) })
              |> list.filter_map(fn(pair) {
                case pair.0 {
                  True -> Ok(pair.1)
                  False -> Error(Nil)
                }
              })
              |> json.array(json.int)
            }),
          ),
        ]),
      ),
    ])
  rsvp.post(
    "/api/events/archery/result",
    body,
    rsvp.expect_ok_response(fn(r) { Saved(result_is_ok(r)) }),
  )
}

fn result_is_ok(r: Result(a, b)) -> Bool {
  case r {
    Ok(_) -> True
    Error(_) -> False
  }
}

// VIEW ------------------------------------------------------------------------

// Pin rows: point at top, wide base at bottom
const pin_rows = [[1], [2, 3], [4, 5, 6], [7, 8, 9, 10]]

pub fn view(model: Model) -> Element(Msg) {
  layout.page("Archery", [
    html.p([], [html.text("Loose your arrows and claim your score.")]),
    html.div(
      [attribute.class("attempts")],
      list.index_map(model.shots, view_shot),
    ),
    html.button([attribute.class("attempt-add"), event.on_click(AddShot)], [
      html.text("+"),
    ]),
    html.p([], [
      html.text(
        "Total: "
        <> int.to_string(compute_total_score(model.shots))
        <> " pts",
      ),
    ]),
    case model.saved {
      True ->
        html.p([attribute.class("saved-message")], [html.text("Score saved!")])
      False -> html.text("")
    },
  ])
}

fn view_shot(shot: List(Bool), shot_idx: Int) -> Element(Msg) {
  html.div([attribute.class("archery-shot")], [
    html.div([attribute.class("archery-shot-header")], [
      html.span([], [html.text("Shot " <> int.to_string(shot_idx + 1))]),
      html.button(
        [attribute.class("attempt-remove"), event.on_click(RemoveShot(shot_idx))],
        [html.text("✕")],
      ),
    ]),
    html.div(
      [attribute.class("cup-triangle")],
      list.map(pin_rows, fn(row) {
        html.div(
          [attribute.class("cup-row")],
          list.map(row, fn(pin) {
            let cup_idx = pin - 1
            let knocked =
              shot
              |> list.drop(cup_idx)
              |> list.first
              |> result.unwrap(False)
            let cls = case knocked {
              True -> "cup cup--knocked"
              False -> "cup"
            }
            html.button(
              [
                attribute.class(cls),
                event.on_click(ToggleCup(shot_idx, cup_idx)),
              ],
              [html.text(int.to_string(pin))],
            )
          }),
        )
      }),
    ),
    html.p([attribute.class("archery-shot-score")], [
      html.text(int.to_string(compute_shot_score(shot)) <> " pts"),
    ]),
  ])
}

fn compute_shot_score(shot: List(Bool)) -> Int {
  list.index_fold(shot, 0, fn(acc, knocked, i) {
    case knocked {
      True -> acc + i + 1
      False -> acc
    }
  })
}

fn compute_total_score(shots: List(List(Bool))) -> Int {
  list.fold(shots, 0, fn(acc, shot) { acc + compute_shot_score(shot) })
}
