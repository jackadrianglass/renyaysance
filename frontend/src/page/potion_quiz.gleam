import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import layout
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp

// MODEL -----------------------------------------------------------------------

const potion_count = 9

const potion_names = [
  "Coloured stripes", "Purple", "Cherry Bottle", "Yellow Flowers", "Pink Flowers",
  "Orange circles", "Blue Mountains", "Vines", "Blue waves, red dots",
]

pub type Model {
  Model(answers: List(String), results: List(Option(Bool)))
}

pub fn init(handle: String) -> #(Model, Effect(Msg)) {
  #(
    Model(
      answers: list.repeat("", potion_count),
      results: list.repeat(None, potion_count),
    ),
    fetch_guesses(handle),
  )
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  SetAnswer(Int, String)
  CheckAnswer(Int)
  GotResult(Int, Result(List(Option(Bool)), rsvp.Error(String)))
  GotGuesses(Result(List(#(String, String, Option(Bool))), rsvp.Error(String)))
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
      let name = case list.drop(potion_names, index) {
        [n, ..] -> n
        [] -> ""
      }
      #(model, do_check_single(handle, index, name, answer))
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

    GotGuesses(Ok(saved)) -> {
      let answers =
        list.map(potion_names, fn(name) {
          list.find_map(saved, fn(triple) {
            let #(n, a, _) = triple
            case n == name {
              True -> Ok(a)
              False -> Error(Nil)
            }
          })
          |> result.unwrap("")
        })
      let results =
        list.map(potion_names, fn(name) {
          list.find_map(saved, fn(triple) {
            let #(n, _, r) = triple
            case n == name {
              True -> Ok(r)
              False -> Error(Nil)
            }
          })
          |> result.unwrap(None)
        })
      #(Model(..model, answers:, results:), effect.none())
    }
    GotGuesses(Error(_)) -> #(model, effect.none())
  }
}

fn fetch_guesses(handle: String) -> Effect(Msg) {
  let decoder = {
    use entries <- decode.field(
      "answers",
      decode.list({
        use name <- decode.field("name", decode.string)
        use answer <- decode.field("answer", decode.string)
        use result <- decode.field("result", decode.optional(decode.bool))
        decode.success(#(name, answer, result))
      }),
    )
    decode.success(entries)
  }
  rsvp.get(
    "/api/events/potion/guesses/" <> handle,
    rsvp.expect_json(decoder, GotGuesses),
  )
}

fn do_check_single(
  handle: String,
  index: Int,
  name: String,
  answer: String,
) -> Effect(Msg) {
  let body =
    json.object([
      #("handle", json.string(handle)),
      #(
        "answers",
        json.array([#(name, answer)], fn(pair) {
          let #(n, a) = pair
          json.object([#("name", json.string(n)), #("answer", json.string(a))])
        }),
      ),
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
      list.zip(potion_names, list.zip(model.answers, model.results))
        |> list.index_map(fn(pair, i) {
          let #(name, #(answer, result)) = pair
          view_potion(name, i, answer, result)
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
  name: String,
  index: Int,
  answer: String,
  result: Option(Bool),
) -> Element(Msg) {
  html.div([attribute.class("potion")], [
    html.span([attribute.class("potion-name")], [html.text(name)]),
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
