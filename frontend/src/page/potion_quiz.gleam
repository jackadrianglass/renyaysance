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

const potion_count = 7

pub type Model {
  Model(attempts: List(Option(Bool)), saved: Bool)
}

pub fn init() -> Model {
  Model(attempts: list.repeat(None, potion_count), saved: False)
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  SetResult(Int, Bool)
  Submit
  Saved(Bool)
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    SetResult(index, correct) -> #(
      Model(
        attempts: list.index_map(model.attempts, fn(attempt, i) {
          case i == index {
            True -> Some(correct)
            False -> attempt
          }
        }),
        saved: False,
      ),
      effect.none(),
    )
    Submit -> #(model, do_submit(handle, model.attempts))
    Saved(ok) -> #(Model(..model, saved: ok), effect.none())
  }
}

fn do_submit(handle: String, attempts: List(Option(Bool))) -> Effect(Msg) {
  let body =
    json.object([
      #("handle", json.string(handle)),
      #(
        "raw",
        json.object([
          #("type", json.string("potion")),
          #(
            "attempts",
            json.array(attempts, fn(attempt) {
              case attempt {
                Some(True) -> json.string("correct")
                Some(False) -> json.string("incorrect")
                None -> json.string("skipped")
              }
            }),
          ),
        ]),
      ),
    ])
  rsvp.post(
    "/api/events/potion/result",
    body,
    rsvp.expect_ok_response(fn(result) { Saved(result |> result_is_ok) }),
  )
}

fn result_is_ok(r: Result(a, b)) -> Bool {
  case r {
    Ok(_) -> True
    Error(_) -> False
  }
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model) -> Element(Msg) {
  layout.page("Potion Quiz", [
    html.p([], [html.text("Identify the correct potion to advance.")]),
    html.div(
      [attribute.class("potions")],
      list.index_map(model.attempts, fn(attempt, i) {
        view_potion(i + 1, i, attempt)
      }),
    ),
    html.p([], [
      html.text(
        "Score: " <> int.to_string(compute_score(model.attempts)) <> " pts",
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

fn view_potion(number: Int, index: Int, attempt: Option(Bool)) -> Element(Msg) {
  html.div([attribute.class("potion")], [
    html.span([attribute.class("potion-name")], [
      html.text("Potion " <> int.to_string(number)),
    ]),
    html.div([attribute.class("attempt-buttons")], [
      html.button(
        [
          event.on_click(SetResult(index, True)),
          attribute.class(case attempt {
            Some(True) -> "attempt-btn attempt-btn--correct selected"
            _ -> "attempt-btn attempt-btn--correct"
          }),
        ],
        [html.text("Correct")],
      ),
      html.button(
        [
          event.on_click(SetResult(index, False)),
          attribute.class(case attempt {
            Some(False) -> "attempt-btn attempt-btn--incorrect selected"
            _ -> "attempt-btn attempt-btn--incorrect"
          }),
        ],
        [html.text("Wrong")],
      ),
    ]),
  ])
}

fn compute_score(attempts: List(Option(Bool))) -> Int {
  list.fold(attempts, 0, fn(acc, attempt) {
    case attempt {
      Some(True) -> acc + 10
      _ -> acc
    }
  })
}
