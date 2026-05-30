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

const win_cap = 6

// MODEL -----------------------------------------------------------------------

pub type Model {
  Model(rounds: List(Bool), saved: Bool)
}

pub fn init() -> Model {
  Model(rounds: [], saved: False)
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  AddWin
  AddLoss
  RemoveLast
  Submit
  Saved(Bool)
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    AddWin -> #(
      Model(rounds: list.append(model.rounds, [True]), saved: False),
      effect.none(),
    )
    AddLoss -> #(
      Model(rounds: list.append(model.rounds, [False]), saved: False),
      effect.none(),
    )
    RemoveLast -> #(
      Model(rounds: drop_last(model.rounds), saved: False),
      effect.none(),
    )
    Submit -> #(model, do_submit(handle, model.rounds))
    Saved(ok) -> #(Model(..model, saved: ok), effect.none())
  }
}

fn drop_last(lst: List(a)) -> List(a) {
  lst |> list.reverse |> list.drop(1) |> list.reverse
}

fn do_submit(handle: String, rounds: List(Bool)) -> Effect(Msg) {
  let body =
    json.object([
      #("handle", json.string(handle)),
      #(
        "raw",
        json.object([
          #("type", json.string("jousting")),
          #(
            "rounds",
            json.array(rounds, fn(win) {
              case win {
                True -> json.string("win")
                False -> json.string("loss")
              }
            }),
          ),
        ]),
      ),
    ])
  rsvp.post(
    "/api/events/jousting/result",
    body,
    rsvp.expect_ok_response(fn(result) { Saved(result_is_ok(result)) }),
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
  let wins = count_wins(model.rounds)
  layout.page("King's Court Jousting", [
    html.p([], [
      html.text(
        "Single-elimination bracket tournament. Winners advance to the final.",
      ),
    ]),
    view_rounds(model.rounds),
    html.p([], [
      html.text("Score: " <> int.to_string(compute_score(wins)) <> " pts"),
    ]),
    html.div([attribute.class("attempt-buttons")], [
      html.button([event.on_click(AddWin)], [html.text("Win")]),
      html.button([event.on_click(AddLoss)], [html.text("Loss")]),
      html.button([event.on_click(RemoveLast)], [html.text("Undo")]),
    ]),
    html.p([], [
      html.text(
        "Wins counted: "
        <> int.to_string(int.min(wins, win_cap))
        <> " / "
        <> int.to_string(win_cap),
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

fn view_rounds(rounds: List(Bool)) -> Element(msg) {
  case rounds {
    [] -> html.p([], [html.text("No rounds yet.")])
    _ ->
      html.div(
        [attribute.class("attempts")],
        list.map(rounds, fn(win) {
          html.span(
            [
              attribute.class(case win {
                True -> "attempt attempt--correct"
                False -> "attempt attempt--incorrect"
              }),
            ],
            [html.text(case win {
              True -> "W"
              False -> "L"
            })],
          )
        }),
      )
  }
}

fn count_wins(rounds: List(Bool)) -> Int {
  list.fold(rounds, 0, fn(acc, win) {
    case win {
      True -> acc + 1
      False -> acc
    }
  })
}

fn compute_score(wins: Int) -> Int {
  int.min(wins, win_cap) * 10
}
