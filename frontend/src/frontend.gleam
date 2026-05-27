import gleam/int
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

type Model {
  Model(count: Int)
}

type Msg {
  Increment
  Decrement
}

fn init(_flags) -> Model {
  Model(count: 0)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    Increment -> Model(count: model.count + 1)
    Decrement -> Model(count: model.count - 1)
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [html.text("Rennyaysance")]),
    html.div([attribute.class("counter")], [
      html.button([event.on_click(Decrement)], [html.text("-")]),
      html.span([], [html.text(int.to_string(model.count))]),
      html.button([event.on_click(Increment)], [html.text("+")]),
    ]),
  ])
}

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
