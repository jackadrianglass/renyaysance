import gleam/dynamic/decode
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
  Model(answers: List(String), results: List(Option(Bool)))
}

pub fn init() -> Model {
  Model(
    answers: list.repeat("", potion_count),
    results: list.repeat(None, potion_count),
  )
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  SetAnswer(Int, String)
  CheckAnswer(Int)
  GotResult(Int, Result(List(Option(Bool)), rsvp.Error(String)))
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    SetAnswer(index, answer) -> #(
      Model(
        ..model,
        answers: list.index_map(model.answers, fn(a, i) {
          case i == index {
            True -> answer
            False -> a
          }
        }),
      ),
      effect.none(),
    )
    CheckAnswer(index) -> {
      let answer = case list.drop(model.answers, index) {
        [a, ..] -> a
        [] -> ""
      }
      #(model, do_check_single(handle, index, answer))
    }
    GotResult(index, Ok(results)) -> {
      let result = case results {
        [r, ..] -> r
        [] -> None
      }
      #(
        Model(
          ..model,
          results: list.index_map(model.results, fn(r, i) {
            case i == index {
              True -> result
              False -> r
            }
          }),
        ),
        effect.none(),
      )
    }
    GotResult(_, Error(_)) -> #(model, effect.none())
  }
}

fn do_check_single(handle: String, index: Int, answer: String) -> Effect(Msg) {
  let body =
    json.object([
      #("handle", json.string(handle)),
      #("answers", json.array([answer], json.string)),
    ])
  rsvp.post(
    "/api/events/potion/check",
    body,
    rsvp.expect_json(results_decoder(), GotResult(index, _)),
  )
}

fn results_decoder() -> decode.Decoder(List(Option(Bool))) {
  use results <- decode.field(
    "results",
    decode.list(decode.then(decode.string, fn(s) {
      case s {
        "correct" -> decode.success(Some(True))
        "incorrect" -> decode.success(Some(False))
        _ -> decode.success(None)
      }
    })),
  )
  decode.success(results)
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model) -> Element(Msg) {
  let any_checked = list.any(model.results, option.is_some)
  layout.page("Potion Quiz", [
    html.p([], [html.text("Identify the correct potion to advance.")]),
    html.div(
      [attribute.class("potions")],
      list.zip(model.answers, model.results)
        |> list.index_map(fn(pair, i) {
          let #(answer, result) = pair
          view_potion(i + 1, i, answer, result)
        }),
    ),
    html.div([attribute.class("potion-footer")], [
      case any_checked {
        False -> html.text("")
        True ->
          html.p([], [
            html.text(
              "Score: " <> int.to_string(compute_score(model.results)) <> " pts",
            ),
          ])
      },
    ]),
  ])
}

fn view_potion(
  number: Int,
  index: Int,
  answer: String,
  result: Option(Bool),
) -> Element(Msg) {
  html.div([attribute.class("potion")], [
    html.span([attribute.class("potion-name")], [
      html.text("Potion " <> int.to_string(number)),
    ]),
    html.input([
      attribute.type_("text"),
      attribute.value(answer),
      attribute.placeholder("Your answer…"),
      attribute.class("potion-answer-input"),
      event.on_input(SetAnswer(index, _)),
    ]),
    html.button(
      [attribute.class("potion-check"), event.on_click(CheckAnswer(index))],
      [html.text("Check")],
    ),
    case result {
      None -> html.text("")
      Some(r) ->
        html.span(
          [
            attribute.class(case r {
              True -> "result-badge result-badge--correct"
              False -> "result-badge result-badge--incorrect"
            }),
          ],
          [
            html.text(case r {
              True -> "✓"
              False -> "✗"
            }),
          ],
        )
    },
  ])
}

fn compute_score(results: List(Option(Bool))) -> Int {
  list.fold(results, 0, fn(acc, r) {
    case r {
      Some(True) -> acc + 10
      _ -> acc
    }
  })
}
