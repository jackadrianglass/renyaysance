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
  Model(answers: List(String), results: Option(List(Option(Bool))))
}

pub fn init() -> Model {
  Model(answers: list.repeat("", potion_count), results: None)
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  SetAnswer(Int, String)
  Submit
  GotResults(Result(List(Option(Bool)), rsvp.Error(String)))
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    SetAnswer(index, answer) -> #(
      Model(
        answers: list.index_map(model.answers, fn(a, i) {
          case i == index {
            True -> answer
            False -> a
          }
        }),
        results: None,
      ),
      effect.none(),
    )
    Submit -> #(model, do_submit(handle, model.answers))
    GotResults(Ok(results)) -> #(
      Model(..model, results: Some(results)),
      effect.none(),
    )
    GotResults(Error(_)) -> #(model, effect.none())
  }
}

fn do_submit(handle: String, answers: List(String)) -> Effect(Msg) {
  let body =
    json.object([
      #("handle", json.string(handle)),
      #("answers", json.array(answers, json.string)),
    ])
  rsvp.post(
    "/api/events/potion/check",
    body,
    rsvp.expect_json(results_decoder(), GotResults),
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
  let indexed = list.index_map(model.answers, fn(answer, i) { #(i, answer) })
  let potions =
    case model.results {
      None -> list.map(indexed, fn(p) { #(p.0, p.1, None) })
      Some(results) ->
        list.zip(indexed, results)
        |> list.map(fn(pair) { #(pair.0.0, pair.0.1, Some(pair.1)) })
    }
  layout.page("Potion Quiz", [
    html.p([], [html.text("Identify the correct potion to advance.")]),
    html.div(
      [attribute.class("potions")],
      list.map(potions, fn(p) {
        let #(i, answer, potion_result) = p
        view_potion(i + 1, i, answer, potion_result)
      }),
    ),
    html.div([attribute.class("potion-footer")], [
      case model.results {
        None -> html.text("")
        Some(results) ->
          html.p([], [
            html.text(
              "Score: " <> int.to_string(compute_score(results)) <> " pts",
            ),
          ])
      },
      html.button([event.on_click(Submit)], [html.text("Submit Answers")]),
    ]),
  ])
}

fn view_potion(
  number: Int,
  index: Int,
  answer: String,
  potion_result: Option(Option(Bool)),
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
    case potion_result {
      None -> html.text("")
      Some(r) ->
        html.span(
          [
            attribute.class(case r {
              Some(True) -> "result-badge result-badge--correct"
              Some(False) -> "result-badge result-badge--incorrect"
              None -> "result-badge result-badge--skipped"
            }),
          ],
          [
            html.text(case r {
              Some(True) -> "Correct"
              Some(False) -> "Incorrect"
              None -> "Skipped"
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
