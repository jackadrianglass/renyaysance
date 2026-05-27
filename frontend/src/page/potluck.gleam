import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("Potluck", [
    html.p([], [html.text("The communal feast — see what's on the table.")]),
  ])
}
