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

const upload_link = "https://drive.proton.me/urls/AYA2VCGXVC#1YcBArVtdjXl"

const items = [
  "With the court jesters",
  "With your favourite costume",
  "With you and Chestnut in action",
  "With a performer",
  "In the stocks",
  "With someone you met today",
  "With your favourite thing in the market",
  "That looks like it could be a Renaissance painting",
  "In the jousting ring",
  "Where you're upside down",
]

// MODEL -----------------------------------------------------------------------

pub type Model {
  Model(checked: List(Bool), saved: Bool)
}

pub fn init() -> Model {
  Model(checked: list.repeat(False, list.length(items)), saved: False)
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  Toggle(Int)
  Saved(Bool)
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    Toggle(index) -> {
      let new_checked =
        list.index_map(model.checked, fn(c, i) {
          case i == index {
            True -> !c
            False -> c
          }
        })
      #(Model(checked: new_checked, saved: False), do_submit(handle, new_checked))
    }
    Saved(ok) -> #(Model(..model, saved: ok), effect.none())
  }
}

fn do_submit(handle: String, checked: List(Bool)) -> Effect(Msg) {
  let body =
    json.object([
      #("handle", json.string(handle)),
      #(
        "raw",
        json.object([
          #("type", json.string("scavenger_hunt")),
          #("items", json.array(checked, json.bool)),
        ]),
      ),
    ])
  rsvp.post(
    "/api/events/scavenger-hunt/result",
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
  let total = list.length(items)
  let collected = list.fold(model.checked, 0, fn(acc, c) {
    case c {
      True -> acc + 1
      False -> acc
    }
  })
  layout.page("Scavenger Hunt", [
    html.p([], [
      html.text(
        "Take a photo of each item below. Upload them all to the shared drive to complete the hunt.",
      ),
    ]),
    html.div(
      [attribute.class("hunt-items")],
      list.zip(items, model.checked)
        |> list.index_map(fn(pair, i) {
          let #(label, is_checked) = pair
          view_item(i, label, is_checked)
        }),
    ),
    html.p([], [
      html.text(
        int.to_string(collected)
        <> " / "
        <> int.to_string(total)
        <> " photos collected",
      ),
    ]),
    case model.saved {
      True ->
        html.p([attribute.class("saved-message")], [
          html.text("Progress saved!"),
        ])
      False -> html.text("")
    },
    html.div([attribute.class("hunt-upload")], [
      html.p([], [html.text("Upload your photos to the shared drive:")]),
      html.a(
        [attribute.href(upload_link), attribute.attribute("target", "_blank")],
        [html.text("Open Shared Drive →")],
      ),
    ]),
  ])
}

fn view_item(index: Int, label: String, is_checked: Bool) -> Element(Msg) {
  let row_cls = case is_checked {
    True -> "hunt-item hunt-item--checked"
    False -> "hunt-item"
  }
  html.div([attribute.class(row_cls)], [
    html.label([attribute.class("hunt-checkbox")], [
      html.input([
        attribute.type_("checkbox"),
        attribute.checked(is_checked),
        event.on_click(Toggle(index)),
      ]),
      html.span([attribute.class("hunt-checkbox-visual")], []),
    ]),
    html.span([attribute.class("hunt-item-text")], [html.text(label)]),
  ])
}
