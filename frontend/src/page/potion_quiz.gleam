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

pub type Model {
  Model(attempts: List(Bool), saved: Bool)
}

pub fn init() -> Model {
  Model(attempts: [], saved: False)
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  AddCorrect
  AddIncorrect
  RemoveLast
  Submit
  Saved(Bool)
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    AddCorrect -> #(
      Model(attempts: list.append(model.attempts, [True]), saved: False),
      effect.none(),
    )
    AddIncorrect -> #(
      Model(attempts: list.append(model.attempts, [False]), saved: False),
      effect.none(),
    )
    RemoveLast -> #(
      Model(attempts: drop_last(model.attempts), saved: False),
      effect.none(),
    )
    Submit -> #(model, do_submit(handle, model.attempts))
    Saved(ok) -> #(Model(..model, saved: ok), effect.none())
  }
}

fn drop_last(lst: List(a)) -> List(a) {
  lst |> list.reverse |> list.drop(1) |> list.reverse
}

fn do_submit(handle: String, attempts: List(Bool)) -> Effect(Msg) {
  let body =
    json.object([
      #("handle", json.string(handle)),
      #(
        "raw",
        json.object([
          #("type", json.string("potion")),
          #(
            "attempts",
            json.array(attempts, fn(correct) {
              case correct {
                True -> json.string("correct")
                False -> json.string("incorrect")
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
    view_attempts(model.attempts),
    html.p([], [
      html.text("Score: " <> int.to_string(compute_score(model.attempts)) <> " pts"),
    ]),
    html.div([attribute.class("attempt-buttons")], [
      html.button([event.on_click(AddCorrect)], [html.text("✓ Correct")]),
      html.button([event.on_click(AddIncorrect)], [html.text("✗ Wrong")]),
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

fn view_attempts(attempts: List(Bool)) -> Element(msg) {
  case attempts {
    [] -> html.p([], [html.text("No attempts yet.")])
    _ ->
      html.div(
        [attribute.class("attempts")],
        list.map(attempts, fn(correct) {
          html.span(
            [
              attribute.class(case correct {
                True -> "attempt attempt--correct"
                False -> "attempt attempt--incorrect"
              }),
            ],
            [html.text(case correct {
              True -> "✓"
              False -> "✗"
            })],
          )
        }),
      )
  }
}

fn compute_score(attempts: List(Bool)) -> Int {
  list.fold(attempts, 0, fn(acc, correct) {
    case correct {
      True -> acc + 10
      False -> acc
    }
  })
}
